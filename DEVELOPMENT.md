# verl 同步与二次开发指南

本仓库通过 [git subtree](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging) 集成了上游 [verl](https://github.com/verl-project/verl)，代码位于 [`verl/`](./verl) 目录，并在其上做二次开发。

采用 subtree（而非 submodule）的原因：clone 仓库即可拿到全部代码，无需额外 `git submodule` 操作，且方便按需同步上游更新。

## 目录结构

```
agent_verl/
├── verl/              # 上游 verl 代码（git subtree 管理，--squash 压缩历史）
├── my_verl/           # 二次开发层：整体替换的模块放这里，运行时覆盖 verl
├── VERL_VERSION       # 当前固定跟踪的上游版本（tag/分支）
├── VENDOR_CHANGES.md  # 二次开发登记表：改了哪些模块、为什么、基于哪个版本
├── sync_verl.sh       # 同步 / 升级上游 verl 的脚本
└── DEVELOPMENT.md     # 本文件
```

## 二次开发策略（重要）

由于我们对 verl 的 **reward / trainer / rollout / data** 等模块有改动，且深浅不一，
采用「**固定版本 + 分层管理**」策略，把「持续解冲突」变成「有计划的版本升级」：

- **固定 release 版本**：不跟 `main`，而是固定到某个 tag（见 `VERL_VERSION`，当前 `v0.8.0`），只在主动决定时升级。
- **整体替换的模块** → 放到 [`my_verl/`](./my_verl)，通过运行时导入覆盖顶掉上游实现，让 `verl/` 保持纯净、升级零冲突。
- **小改的模块** → 直接留在 `verl/` 内，升级时接受少量冲突，并在 [`VENDOR_CHANGES.md`](./VENDOR_CHANGES.md) 登记。

在训练入口最开头启用覆盖：

```python
import my_verl
my_verl.apply_overrides()   # 必须在 import verl 业务代码之前调用
```

## 同步 / 升级上游 verl

```bash
./sync_verl.sh                # 同步到 VERL_VERSION 记录的版本
./sync_verl.sh v0.8.0         # 临时指定分支/tag（不改 VERL_VERSION）
./sync_verl.sh --set v0.9.0   # 升级：写入新版本到 VERL_VERSION 并同步
```

升级后按 [`VENDOR_CHANGES.md`](./VENDOR_CHANGES.md) 的流程，对被接管/小改的模块做三方对比，确认要吸收哪些上游变化，然后：

```bash
# 若有冲突：解决后
git add verl/ && git commit
# 最后推送
git push origin main
```

对被整体替换的模块，查看上游从旧版到新版改了什么，决定是否移植：

```bash
git diff <旧版tag> <新版tag> -- verl/verl/workers/xxx.py
```

## 初始搭建记录（仅供参考，无需重复执行）

```bash
# 1. 添加上游 remote
git remote add verl-upstream https://github.com/verl-project/verl.git
git fetch verl-upstream

# 2. 将 verl 拉入 verl/ 子目录（--squash 压缩其历史为一条 commit）
git subtree add --prefix=verl verl-upstream main --squash
```

## 注意事项

- **保留 `verl-upstream` 这个 remote**：`subtree pull` 依赖它，删除后同步会失败（脚本会在缺失时自动重新添加）。
- **始终带上 `--squash`**：与初始 add 时保持一致，避免把 verl 的完整历史灌入本仓库导致合并混乱。
- **改动 verl 相关代码时，务必更新 `VENDOR_CHANGES.md`**，否则升级时很难判断上游变化要不要吸收。
- **优先用 `my_verl/` 覆盖而非直接改 `verl/`**：能整体替换的就别在 `verl/` 里改，减少升级冲突。
