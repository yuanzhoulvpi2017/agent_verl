# agent_verl

本仓库通过 [git subtree](https://git-scm.com/book/en/v2/Git-Tools-Advanced-Merging) 集成了上游 [verl](https://github.com/verl-project/verl)，代码位于 [`verl/`](./verl) 目录。

采用 subtree（而非 submodule）的原因：clone 仓库即可拿到全部代码，无需额外 `git submodule` 操作，且方便频繁同步上游更新。

## 目录结构

```
agent_verl/
├── verl/            # 上游 verl 代码（由 git subtree 管理，通过 --squash 压缩历史）
├── sync_verl.sh     # 一键同步上游 verl 的脚本
└── README.md
```

## 同步上游 verl 更新

### 方式一：使用脚本（推荐）

```bash
./sync_verl.sh            # 从上游 main 分支同步
./sync_verl.sh v0.8.0     # 从指定分支或 tag 同步
```

### 方式二：直接用 git 命令

```bash
git subtree pull --prefix=verl verl-upstream main --squash
```

同步完成后推送到自己的远程：

```bash
git push origin main
```

## 初始搭建记录（仅供参考，无需重复执行）

本目录是这样一次性建立的：

```bash
# 1. 添加上游 remote
git remote add verl-upstream https://github.com/verl-project/verl.git
git fetch verl-upstream

# 2. 将 verl 的 main 分支拉入 verl/ 子目录（--squash 压缩其历史为一条 commit）
git subtree add --prefix=verl verl-upstream main --squash
```

## 注意事项

- **保留 `verl-upstream` 这个 remote**：`subtree pull` 依赖它，删除后同步会失败（脚本会在缺失时自动重新添加）。
- **始终带上 `--squash`**：与初始 add 时保持一致，避免把 verl 的完整历史灌入本仓库导致合并混乱。
- **跟踪特定版本**：如果想固定在某个稳定版本，把命令里的 `main` 换成对应分支（如 `release/v0.8.0`）或 tag（如 `v0.8.0`）。
- **向上游贡献改动**（一般用不到）：`git subtree push --prefix=verl verl-upstream <你的分支>`。
