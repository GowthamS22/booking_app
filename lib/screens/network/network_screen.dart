import 'package:badminton_app/components/nonetwork_widget.dart';
import 'package:flutter/material.dart';

class NetworkScreen extends StatefulWidget {
  const NetworkScreen({Key? key}) : super(key: key);

  @override
  State<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends State<NetworkScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NoNetworkErrorWidget(),
    );
  }
}
