import 'package:atsign_atmosphere_pro/data_models/file_transfer.dart';
import 'package:atsign_atmosphere_pro/demo_data/file_transfer_data.dart';
import 'package:atsign_atmosphere_pro/desktop_screens/desktop_history/widgets/desktop_received_file_details.dart';
import 'package:atsign_atmosphere_pro/desktop_screens/desktop_history/widgets/desktop_received_file_list_tile.dart';
import 'package:atsign_atmosphere_pro/desktop_screens/desktop_history/widgets/desktop_sent_file_details.dart';
import 'package:atsign_atmosphere_pro/desktop_screens/desktop_history/widgets/desktop_sent_file_list_tile.dart';
import 'package:atsign_atmosphere_pro/desktop_screens/desktop_history/widgets/desktop_transfer_overlapping.dart';
import 'package:atsign_atmosphere_pro/screens/common_widgets/provider_handler.dart';
import 'package:atsign_atmosphere_pro/screens/history/widgets/received_file_list_tile.dart';
import 'package:atsign_atmosphere_pro/services/size_config.dart';
import 'package:atsign_atmosphere_pro/utils/colors.dart';
import 'package:atsign_atmosphere_pro/utils/images.dart';
import 'package:atsign_atmosphere_pro/utils/text_strings.dart';
import 'package:atsign_atmosphere_pro/utils/text_styles.dart';
import 'package:atsign_atmosphere_pro/view_models/history_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:atsign_atmosphere_pro/desktop_routes/desktop_routes.dart';

class DesktopHistoryScreen extends StatefulWidget {
  final int tabIndex;
  DesktopHistoryScreen({this.tabIndex = 0});
  @override
  _DesktopHistoryScreenState createState() => _DesktopHistoryScreenState();
}

class _DesktopHistoryScreenState extends State<DesktopHistoryScreen>
    with SingleTickerProviderStateMixin {
  TabController _controller;
  HistoryProvider historyProvider;
  int sentSelectedIndex = 0, receivedSelectedIndex = 0;
  FileHistory selectedFileData;
  bool isSentTab = true;

  @override
  void didChangeDependencies() async {
    if (historyProvider == null) {
      _controller =
          TabController(length: 2, vsync: this, initialIndex: widget.tabIndex);
      _controller.addListener(onTabChanged);
      historyProvider = Provider.of<HistoryProvider>(context);
    }
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.removeListener(onTabChanged);
    super.dispose();
  }

  onTabChanged({int index}) {
    if (index == null) {
      index = _controller.index;
    }
    if (index == 0) {
      isSentTab = true;
    } else if (index == 1) {
      isSentTab = false;
      selectedFileData = null;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: ColorConstants.scaffoldColor,
      body: SingleChildScrollView(
          child: Row(
        children: <Widget>[
          Container(
            color: ColorConstants.fadedBlue,
            height: SizeConfig().screenHeight,
            width: (SizeConfig().screenWidth * 0.5 - 35),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 80,
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: TabBar(
                        labelColor: ColorConstants.fontPrimary,
                        indicatorWeight: 5,
                        indicatorColor: Colors.black,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelStyle: CustomTextStyles.primaryBold14,
                        unselectedLabelStyle:
                            CustomTextStyles.secondaryRegular14,
                        controller: _controller,
                        tabs: [
                          Text(
                            TextStrings().sent,
                            style: TextStyle(letterSpacing: 0.1, fontSize: 20),
                          ),
                          Text(
                            TextStrings().received,
                            style: TextStyle(letterSpacing: 0.1, fontSize: 20),
                          )
                        ],
                      ),
                    ),
                    Positioned(
                        top: 30,
                        left: 30,
                        child: InkWell(
                          onTap: () {
                            DesktopSetupRoutes.nested_pop();    
                          },
                          child: Icon(Icons.arrow_back,
                              size: 20, color: Colors.black),
                        )),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    controller: _controller,
                    children: [
                      FutureBuilder(builder: (BuildContext context, snapshot) {
                        var sentHistory = DemoData().getFileHistoryData();
                        return ListView.separated(
                          padding: EdgeInsets.only(bottom: 170.toHeight),
                          physics: AlwaysScrollableScrollPhysics(),
                          separatorBuilder: (context, index) {
                            return Divider(
                              indent: 16.toWidth,
                            );
                          },
                          itemCount: sentHistory.length,
                          itemBuilder: (context, index) {
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  sentSelectedIndex = index;
                                  selectedFileData = sentHistory[index];
                                });
                              },
                              child: DesktopSentFilesListTile(
                                sentHistory: sentHistory[index],
                                key: Key(sentHistory[index].fileDetails.key),
                                isSelected:
                                    index == sentSelectedIndex ? true : false,
                              ),
                            );
                          },
                        );
                      }),
                      // ProviderHandler<HistoryProvider>(
                      //   functionName: historyProvider.SENT_HISTORY,
                      //   showError: true,
                      //   successBuilder: (provider) {
                      //     return (provider.sentHistory.isEmpty)
                      //         ? Center(
                      //             child: Text('No files sent',
                      //                 style: TextStyle(fontSize: 15.toFont)),
                      //           )
                      //         : ListView.separated(
                      //             padding:
                      //                 EdgeInsets.only(bottom: 170.toHeight),
                      //             physics: AlwaysScrollableScrollPhysics(),
                      //             separatorBuilder: (context, index) {
                      //               return Divider(
                      //                 indent: 16.toWidth,
                      //               );
                      //             },
                      //             itemCount: provider.sentHistory.length,
                      //             itemBuilder: (context, index) {
                      //               return InkWell(
                      //                 onTap: () {
                      //                   setState(() {
                      //                     sentSelectedIndex = index;
                      //                     selectedFileData =
                      //                         provider.sentHistory[index];
                      //                   });
                      //                 },
                      //                 child: DesktopSentFilesListTile(
                      //                   sentHistory:
                      //                       provider.sentHistory[index],
                      //                   key: Key(provider.sentHistory[index]
                      //                       .fileDetails.key),
                      //                   isSelected: index == sentSelectedIndex
                      //                       ? true
                      //                       : false,
                      //                 ),
                      //               );
                      //             },
                      //           );
                      //   },
                      //   errorBuilder: (provider) => Center(
                      //     child: Text('Some error occured'),
                      //   ),
                      //   load: (provider) async {
                      //     provider.getSentHistory();
                      //   },
                      // ),

                      FutureBuilder(builder: (BuildContext context, snapshot) {
                        List<FileTransfer> receivedHistoryLogs = [];
                        var sentHistory = DemoData().getFileHistoryData();
                        DemoData().getFileHistoryData().forEach((element) {
                          receivedHistoryLogs.add(element.fileDetails);
                        });
                        return ListView.separated(
                          padding: EdgeInsets.only(bottom: 170.toHeight),
                          physics: AlwaysScrollableScrollPhysics(),
                          separatorBuilder: (context, index) => Divider(
                            indent: 16.toWidth,
                          ),
                          itemCount: receivedHistoryLogs.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  receivedSelectedIndex = index;
                                });
                              },
                              child: DesktopReceivedFilesListTile(
                                key: UniqueKey(),
                                sentHistory: sentHistory[index],
                                isSelected: index == receivedSelectedIndex
                                    ? true
                                    : false,
                              ),
                            ),
                          ),
                        );
                      })
                      // ProviderHandler<HistoryProvider>(
                      //   functionName: historyProvider.RECEIVED_HISTORY,
                      //   load: (provider) async {
                      //     await provider.getReceivedHistory();
                      //   },
                      //   showError: true,
                      //   successBuilder: (provider) {
                      //     return (provider.receivedHistoryLogs.isEmpty)
                      //         ? Center(
                      //             child: Text(
                      //               'No files received',
                      //               style: TextStyle(fontSize: 15.toFont),
                      //             ),
                      //           )
                      //         : ListView.separated(
                      //             padding:
                      //                 EdgeInsets.only(bottom: 170.toHeight),
                      //             physics: AlwaysScrollableScrollPhysics(),
                      //             separatorBuilder: (context, index) => Divider(
                      //               indent: 16.toWidth,
                      //             ),
                      //             itemCount:
                      //                 provider.receivedHistoryLogs.length,
                      //             itemBuilder: (context, index) => Padding(
                      //               padding: const EdgeInsets.all(8.0),
                      //               child: InkWell(
                      //                 onTap: () {
                      //                   setState(() {
                      //                     receivedSelectedIndex = index;
                      //                   });
                      //                 },
                      //                 child: DesktopReceivedFilesListTile(
                      //                   key: UniqueKey(),
                      //                   sentHistory:
                      //                       provider.sentHistory[index],
                      //                   isSelected:
                      //                       index == receivedSelectedIndex
                      //                           ? true
                      //                           : false,
                      //                 ),
                      //               ),
                      //             ),
                      //           );
                      //   },
                      //   errorBuilder: (provider) => Center(
                      //     child: Text('Some error occured'),
                      //   ),
                      // ),
                    ],
                  ),
                )
              ],
            ),
          ),
          Container(
            width: (SizeConfig().screenWidth * 0.5 - 35),
            child: isSentTab
                ? DesktopSentFileDetails(selectedFileData: selectedFileData)
                : DesktopReceivedFileDetails(
                    selectedFileData: selectedFileData),
          )
        ],
      )),
    );
  }
}
