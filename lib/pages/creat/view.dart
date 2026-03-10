import 'package:flutter/material.dart';
import 'package:hajimipass/pages/creat/control.dart';
import 'package:hajimipass/pages/edit/view.dart';

class CreatePage extends StatelessWidget {
  const CreatePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 复用 EditPage 的 UI，但传入 CreateController
    // 由于 CreateController 继承自 EditController，EditPage 可以正常工作
    // 我们需要确保 Controller 在 EditPage 销毁时被正确 dispose
    // EditPage 的实现中已经处理了如果 controller 是外部传入的情况，
    // 但是这里我们是在 build 方法里每次都创建新的 Controller 吗？
    // 不，这会导致每次 rebuild 都创建新 controller，这是不对的。
    // 正确的做法是：
    // 1. CreatePage 本身是一个 StatefulWidget，维护 CreateController 的生命周期
    // 2. 或者 EditPage 能够识别并处理，但 EditPage 已经是 StatefulWidget。
    // 
    // 鉴于 EditPage 已经是一个通用的编辑器，CreatePage 最简单的实现就是直接返回一个配置好的 EditPage。
    // 为了管理 CreateController 的生命周期，我们可以在 EditPage 的 initState 中处理 controller 的创建逻辑，
    // 或者我们在这里创建一个 StatefulWrapper。
    // 
    // 不过，为了符合 EditPage 的设计 (接受 controller)，我们可以这样做：
    // 如果 EditPage 负责 dispose 传入的 controller (这通常是不推荐的，但在这种紧密耦合的场景下可能方便)，
    // 或者我们让 EditPage 根据某种标志来创建 CreateController。
    // 
    // 最好的方式：CreatePage 只是一个壳，它通过路由参数或者直接构建 EditPage。
    // 这里我们使用 StatefulWidget 来持有 controller。

    return const CreatePageWrapper();
  }
}

class CreatePageWrapper extends StatefulWidget {
  const CreatePageWrapper({super.key});

  @override
  State<CreatePageWrapper> createState() => _CreatePageWrapperState();
}

class _CreatePageWrapperState extends State<CreatePageWrapper> {
  late final CreateController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CreateController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EditPage(
      controller: _controller,
      title: '添加账号',
    );
  }
}
