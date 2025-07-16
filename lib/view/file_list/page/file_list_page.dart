import 'package:flutter/material.dart';

class FileListPage extends StatelessWidget {
  const FileListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Container(
            child: Row(
              children: [
                Icon(Icons.description, color: Colors.black,),
                SizedBox(width: 3,),
                Text("2025-04-27 19_02_15.opus", style: TextStyle(fontSize: 15, color: Colors.blueAccent),)
              ],
            )
          ),
        ],
      ),
    );
  }
}
