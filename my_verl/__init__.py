"""my_verl —— 对 verl 的二次开发层。

这里放「整体替换」的模块实现，通过 `apply_overrides()` 在运行时顶掉上游 verl 的
对应实现，从而让 verl/ 子目录保持纯净、方便升级同步。

用法：在你的训练入口最开头（在 import verl 的业务代码之前）调用一次：

    import my_verl
    my_verl.apply_overrides()

具体覆盖了哪些模块，请同步登记到根目录 VENDOR_CHANGES.md。
"""

from __future__ import annotations


def apply_overrides() -> None:
    """安装所有自定义覆盖。按需在下面注册。"""
    _override_example()


def _override_example() -> None:
    """示例：用 my_verl 的实现替换 verl 里某个模块的符号。

    两种常见做法，按需选择：

    1) 猴子补丁（改已存在的类/函数）——适合替换个别符号：

        import verl.workers.reward_manager as _rm
        from my_verl.workers.reward_manager import MyRewardManager
        _rm.RewardManager = MyRewardManager

    2) 模块级替换（整个模块换成自己的）——适合整体重写：

        import sys
        import my_verl.workers.reward_manager as _my_rm
        sys.modules["verl.workers.reward_manager"] = _my_rm

    注意：模块级替换要在 verl 首次 import 该模块「之前」执行才最干净，
    所以务必在入口最开头调用 apply_overrides()。
    """
    # 目前没有启用任何覆盖，添加时删掉这行 pass 并按上面示例实现。
    pass
