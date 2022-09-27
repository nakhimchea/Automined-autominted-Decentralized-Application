import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Decentralized Application",
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  final String _rpcUrl = 'http://10.0.2.2:7545';
  final String _wsUrl = 'ws://10.0.2.2:7545/';
  final String _pkAcc0 =
      '072c9fadbdc5aab15ce6fa81910036d61b694456a25beaa293245ff07f204c82';

  final Client _httpClient = Client();
  Web3Client? _bscClient;

  DeployedContract? _contract;
  EthereumAddress? _contractAddress;
  int? _currentBlockNumber;
  ContractFunction? _contractFunction;

  Credentials? _credentials;
  EthereumAddress? _addressAcc0;
  EtherAmount _etherAmount = EtherAmount.zero();

  Future<void> getDeployment() async {
    setState(() => _isLoading = true);
    debugPrint('Getting contract ABI ~');
    final abiString =
        await rootBundle.loadString('src/artifacts/WingPoint.json');
    final jsonABI = jsonDecode(abiString);
    final abiCode = jsonEncode(jsonABI['abi']);
    _contractAddress =
        EthereumAddress.fromHex(jsonABI['networks']['5777']['address']);
    _contract = DeployedContract(
        ContractAbi.fromJson(abiCode, 'WingPoint'), _contractAddress!);

    // Extracting the functions, declared in contract.
    _contractFunction = _contract!.function('getOwner');
  }

  Future<void> initalization() async {
    debugPrint('Through here: 1');
    _bscClient = Web3Client(
      _rpcUrl,
      _httpClient,
      socketConnector: () => IOWebSocketChannel.connect(_wsUrl).cast<String>(),
    );
    debugPrint('Through here: 2');

    _credentials = EthPrivateKey.fromHex(_pkAcc0);
    debugPrint('Through here: 3');
    _addressAcc0 = await _credentials?.extractAddress();
    debugPrint('Through here: 4');
    if (_bscClient != null) {
      _currentBlockNumber = await _bscClient!.getBlockNumber();
      _etherAmount = await _bscClient!.getBalance(_addressAcc0!);
      debugPrint((await _bscClient!.getChainId()).toString());
    }
    debugPrint('Through here: 5');
    if (_bscClient != null && _contract != null && _contractFunction != null) {
      debugPrint((await _bscClient!.call(
              contract: _contract!, function: _contractFunction!, params: []))
          .toString());
    }
    debugPrint('Through here: 6');

    setState(() => _isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    getDeployment().whenComplete(() => initalization());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Center(
          child: _isLoading
              ? const CircularProgressIndicator.adaptive()
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Your address is:\n ${_addressAcc0?.hexEip55}',
                      textAlign: TextAlign.center,
                    ),
                    Text(
                        'You have \$ETH ${_etherAmount.getValueInUnit(EtherUnit.ether).toString()}'),
                    const SizedBox(height: 10),
                    Text('Current Block No: ${_currentBlockNumber.toString()}'),
                  ],
                ),
        ),
      ),
    );
  }
}
