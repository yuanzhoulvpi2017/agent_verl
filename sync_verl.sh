#!/usr/bin/env bash
#
# 同步上游 verl 到本仓库的 verl/ 子目录（基于 git subtree）。
#
# 用法：
#   ./sync_verl.sh              # 默认从 verl-upstream 的 main 分支同步
#   ./sync_verl.sh v0.8.0       # 从指定分支/tag 同步
#
set -euo pipefail

PREFIX="verl"
REMOTE="verl-upstream"
REMOTE_URL="https://github.com/verl-project/verl.git"
REF="${1:-main}"

# 若 remote 不存在则自动添加
if ! git remote get-url "${REMOTE}" >/dev/null 2>&1; then
  echo ">> remote '${REMOTE}' 不存在，正在添加..."
  git remote add "${REMOTE}" "${REMOTE_URL}"
fi

echo ">> 正在从 ${REMOTE}/${REF} 同步到 ${PREFIX}/ ..."
git fetch "${REMOTE}" "${REF}"
git subtree pull --prefix="${PREFIX}" "${REMOTE}" "${REF}" --squash

echo ">> 同步完成。别忘了 push："
echo "   git push origin \$(git rev-parse --abbrev-ref HEAD)"
