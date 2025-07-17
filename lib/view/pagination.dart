import 'package:flutter/material.dart';

class Pagination extends StatefulWidget {
  /// 总数量
  final int total;

  /// 总页数
  final int totalPage;

  /// 当前页码（从 1 开始）
  final int currentPage;

  /// 页码切换回调，返回目标页码
  final ValueChanged<int> onPageChanged;

  const Pagination({
    super.key,
    required this.total,
    required this.totalPage,
    required this.currentPage,
    required this.onPageChanged,
  });

  @override
  State<Pagination> createState() => _PaginationState();
}

class _PaginationState extends State<Pagination> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentPage.toString());
  }

  @override
  void didUpdateWidget(Pagination oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 保证外部切换时文本同步
    if (oldWidget.currentPage != widget.currentPage) {
      _controller.text = widget.currentPage.toString();
    }
  }

  void _jumpToPage() {
    final input = int.tryParse(_controller.text);
    if (input != null && input > 0 && input <= widget.totalPage) {
      widget.onPageChanged(input);
    } else {
      // 你可以自定义这里的错误提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("请输入有效的页码！")),
      );
      _controller.text = widget.currentPage.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一页
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: widget.currentPage > 1
              ? () => widget.onPageChanged(widget.currentPage - 1)
              : null,
        ),
        // 当前页输入框
        SizedBox(
          width: 48,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _jumpToPage(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(vertical: 4),
            ),
          ),
        ),
        Text(" / ${widget.totalPage}", style: TextStyle(fontSize: 14)),
        // 跳转按钮
        Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: ElevatedButton(
            onPressed: _jumpToPage,
            child: const Text('跳转', style: TextStyle(fontSize: 14),),
          ),
        ),
        SizedBox(width: 3,),
        Text("共${widget.total}个", style: TextStyle(fontSize: 14)),
        // 下一页
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: widget.currentPage < widget.totalPage
              ? () => widget.onPageChanged(widget.currentPage + 1)
              : null,
        ),
      ],
    );
  }
}
