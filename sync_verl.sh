#!/usr/bin/env bash
#
# 同步上游 verl 到本仓库的 verl/ 子目录（基于 git subtree）。
#
# 版本固定策略：默认从 VERL_VERSION 文件读取要跟踪的 tag/分支，
# 便于「固定 release 版本、按需升级」的工作流。
#
# 用法：
#   ./sync_verl.sh                # 同步到 VERL_VERSION 里记录的版本
#   ./sync_verl.sh v0.8.0         # 临时指定分支/tag（不改 VERL_VERSION）
#   ./sync_verl.sh --set v0.8.0   # 升级：验证版本存在后写入 VERL_VERSION 并同步
#
set -euo pipefail

PREFIX="verl"
REMOTE="verl-upstream"
REMOTE_URL="https://github.com/verl-project/verl.git"
VERSION_FILE="VERL_VERSION"

# git subtree pull 要求工作树干净，否则会报 "working tree has modifications. Cannot add."
# 提前检查，避免出现「VERL_VERSION 已改但 verl/ 实际没同步」的不一致。
if [[ -n "$(git status --porcelain)" ]]; then
  echo "!! 工作树有未提交改动，git subtree 无法同步。" >&2
  echo "   请先提交或暂存后再试：git commit / git stash" >&2
  git status --short >&2
  exit 1
fi

# 解析参数（--set 的写文件操作推迟到 fetch 成功验证 ref 之后，避免写脏 VERL_VERSION）
PERSIST_VERSION=""
if [[ "${1:-}" == "--set" ]]; then
  if [[ -z "${2:-}" ]]; then
    echo "!! --set 需要一个版本参数，例如：./sync_verl.sh --set v0.8.0" >&2
    exit 1
  fi
  REF="${2}"
  PERSIST_VERSION="${2}"
elif [[ -n "${1:-}" ]]; then
  REF="${1}"
else
  if [[ ! -f "${VERSION_FILE}" ]]; then
    echo "!! 找不到 ${VERSION_FILE}，且未提供版本参数。" >&2
    echo "   请执行：./sync_verl.sh --set <版本>" >&2
    exit 1
  fi
  REF="$(tr -d '[:space:]' < "${VERSION_FILE}")"
fi

# 若 remote 不存在则自动添加
if ! git remote get-url "${REMOTE}" >/dev/null 2>&1; then
  echo ">> remote '${REMOTE}' 不存在，正在添加..."
  git remote add "${REMOTE}" "${REMOTE_URL}"
fi

echo ">> 正在校验并拉取 ${REMOTE}/${REF} ..."
if ! git fetch "${REMOTE}" "${REF}"; then
  echo "!! 上游不存在 ref '${REF}'，同步终止（VERL_VERSION 未改动）。" >&2
  echo "   可用的 release tag 见：git tag | grep '^v'" >&2
  exit 1
fi

# 先做 subtree pull（此时工作树仍干净，满足其要求）
echo ">> 正在从 ${REMOTE}/${REF} 同步到 ${PREFIX}/ ..."
git subtree pull --prefix="${PREFIX}" "${REMOTE}" "${REF}" --squash

# 同步成功后再持久化版本号（写文件会弄脏工作树，必须放在 subtree pull 之后）
if [[ -n "${PERSIST_VERSION}" ]]; then
  echo "${PERSIST_VERSION}" > "${VERSION_FILE}"
  echo ">> 已将跟踪版本更新为 ${PERSIST_VERSION}（写入 ${VERSION_FILE}），记得一并提交。"
fi

cat <<'EOF'

>> 同步完成。
   如果出现冲突：解决后 git add verl/ && git commit
   升级后请检查「被接管/小改的模块」，参考 VENDOR_CHANGES.md 做三方对比。
   最后别忘了推送：git push origin $(git rev-parse --abbrev-ref HEAD)
EOF
