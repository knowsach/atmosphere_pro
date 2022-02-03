import 'dart:convert';
import 'dart:io';
import 'package:at_client_mobile/at_client_mobile.dart';
import 'package:at_commons/at_commons.dart';
import 'package:at_contacts_flutter/services/contact_service.dart';
import 'package:atsign_atmosphere_pro/data_models/file_modal.dart';
import 'package:atsign_atmosphere_pro/data_models/file_transfer.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/apk.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/audios.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/documents.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/photos.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/recents.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/unknowns.dart';
import 'package:atsign_atmosphere_pro/screens/my_files/widgets/videos.dart';
import 'package:atsign_atmosphere_pro/services/backend_service.dart';
import 'package:atsign_atmosphere_pro/services/navigation_service.dart';
import 'package:atsign_atmosphere_pro/services/notification_service.dart';
import 'package:atsign_atmosphere_pro/utils/constants.dart';
import 'package:atsign_atmosphere_pro/utils/file_types.dart';
import 'package:atsign_atmosphere_pro/view_models/base_model.dart';
import 'package:atsign_atmosphere_pro/view_models/file_download_checker.dart';
import 'package:flutter/cupertino.dart';
import 'package:at_client/src/stream/file_transfer_object.dart';
import 'package:at_client/src/service/encryption_service.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:at_client/src/service/notification_service.dart';
import 'package:provider/provider.dart';

class HistoryProvider extends BaseModel {
  String SENT_HISTORY = 'sent_history';
  String RECEIVED_HISTORY = 'received_history';
  String RECENT_HISTORY = 'recent_history';
  String ADD_RECEIVED_FILE = 'add_received_file';
  String UPDATE_RECEIVED_RECORD = 'update_received_record';
  String SET_FILE_HISTORY = 'set_flie_history';
  String SET_RECEIVED_HISTORY = 'set_received_history';
  String GET_ALL_FILE_DATA = 'get_all_file_data';
  String DOWNLOAD_FILE = 'download_file';
  List<FileHistory> sentHistory = [];
  List<FileTransfer> receivedHistoryLogs = [];
  List<FileTransfer> receivedHistoryNew = [];
  Map<String, Map<String, bool>> downloadedFileAcknowledgement = {};
  String state;

  // on first transfer history fetch, we show loader in history screen.
  // on second attempt we keep the status as idle.
  bool isSyncedDataFetched = false;
  List<FilesDetail> sentPhotos,
      sentVideos,
      sentAudio,
      sentApk,
      sentDocument = [];

  List<FilesDetail> receivedPhotos,
      receivedVideos,
      receivedAudio,
      receivedApk,
      receivedDocument,
      recentFile = [],
      receivedUnknown = [];
  List<String> tabNames = ['Recents'];

  List<FilesModel> receivedHistory, receivedAudioModel = [];
  List<Widget> tabs = [Recents()];
  String SORT_FILES = 'sort_files';
  String POPULATE_TABS = 'populate_tabs';
  Map receivedFileHistory = {'history': []};
  Map sendFileHistory = {'history': []};
  String SORT_LIST = 'sort_list';
  BackendService backendService = BackendService.getInstance();
  String app_lifecycle_state;

  resetData() {
    receivedHistory = [];
    receivedAudioModel = [];
    sendFileHistory = {'history': []};
    downloadedFileAcknowledgement = {};
  }

  setFileTransferHistory(
    FileTransferObject fileTransferObject,
    List<String> sharedWithAtsigns,
    Map<String, FileTransferObject> fileShareResult, {
    bool isEdit = false,
  }) async {
    FileHistory fileHistory = convertFileTransferObjectToFileHistory(
      fileTransferObject,
      sharedWithAtsigns,
      fileShareResult,
    );

    setStatus(SET_FILE_HISTORY, Status.Loading);
    await getSentHistory();
    AtKey atKey = AtKey()
      ..metadata = Metadata()
      ..key = MixedConstants.SENT_FILE_HISTORY;

    if (isEdit) {
      int index = sentHistory.indexWhere((element) =>
          element?.fileDetails?.key?.contains(fileHistory.fileDetails.key));

      if (index > -1) {
        sendFileHistory['history'][index] = fileHistory.toJson();
        sentHistory[index] = fileHistory;
      }
    } else {
      sendFileHistory['history'].insert(0, (fileHistory.toJson()));
      sentHistory.insert(0, fileHistory);
    }

    try {
      var result = await backendService.atClientInstance
          .put(atKey, json.encode(sendFileHistory));
      setStatus(SET_FILE_HISTORY, Status.Done);
      return result;
    } catch (e) {
      setError(SET_FILE_HISTORY, e.toString());
      setStatus(SET_FILE_HISTORY, Status.Error);
    }
  }

  updateFileHistoryDetail(FileHistory fileHistory) async {
    AtKey atKey = AtKey()
      ..metadata = Metadata()
      ..key = MixedConstants.SENT_FILE_HISTORY;

    int index = sentHistory.indexWhere((element) =>
        element?.fileDetails?.key?.contains(fileHistory.fileDetails.key));

    var result = false;
    if (index > -1) {
      sendFileHistory['history'][index] = fileHistory.toJson();
      sentHistory[index] = fileHistory;

      result = await backendService.atClientInstance
          .put(atKey, json.encode(sendFileHistory));
      notifyListeners();
    }
    return result;
  }

  getSentHistory() async {
    setStatus(SENT_HISTORY, Status.Loading);
    try {
      sentHistory = [];
      AtKey key = AtKey()
        ..key = MixedConstants.SENT_FILE_HISTORY
        ..sharedBy = AtClientManager.getInstance().atClient.getCurrentAtSign()
        ..metadata = Metadata();
      var keyValue =
          await backendService.atClientInstance.get(key).catchError((e) {
        print('error in getSentHistory : $e');
      });
      if (keyValue != null && keyValue.value != null) {
        try {
          Map historyFile = json.decode((keyValue.value) as String) as Map;
          sendFileHistory['history'] = historyFile['history'];
          historyFile['history'].forEach((value) {
            FileHistory filesModel = FileHistory.fromJson((value));
            // checking for download acknowledged
            filesModel.sharedWith = checkIfileDownloaded(
              filesModel.sharedWith,
              filesModel.fileTransferObject.transferId,
            );
            sentHistory.add(filesModel);
          });
        } catch (e) {
          print('error in file model conversion in getSentHistory: $e');
        }
      }

      setStatus(SENT_HISTORY, Status.Done);
    } catch (error) {
      setError(SENT_HISTORY, error.toString());
    }
  }

  List<ShareStatus> checkIfileDownloaded(
      List<ShareStatus> shareStatus, String transferId) {
    if (downloadedFileAcknowledgement[transferId] != null) {
      for (int i = 0; i < shareStatus.length; i++) {
        if (downloadedFileAcknowledgement[transferId][shareStatus[i].atsign] !=
            null) {
          shareStatus[i].isFileDownloaded = true;
        }
      }
    }
    return shareStatus;
  }

  getFileDownloadedAcknowledgement() async {
    var atKeys = await AtClientManager.getInstance()
        .atClient
        .getAtKeys(regex: MixedConstants.FILE_TRANSFER_ACKNOWLEDGEMENT);
    atKeys.retainWhere((element) => !compareAtSign(element.sharedBy,
        AtClientManager.getInstance().atClient.getCurrentAtSign()));

    await Future.forEach(atKeys, (AtKey atKey) async {
      try {
        AtValue atValue = await AtClientManager.getInstance()
            .atClient
            .get(atKey)
            .catchError((e) {
          print('error in get in getFileDownloadedAcknowledgement : $e');
        });
        if (atValue != null && atValue.value != null) {
          var downloadAcknowledgement =
              DownloadAcknowledgement.fromJson(jsonDecode(atValue.value));

          if (downloadedFileAcknowledgement[
                  downloadAcknowledgement.transferId] !=
              null) {
            downloadedFileAcknowledgement[downloadAcknowledgement.transferId]
                [formatAtsign(atKey.sharedBy)] = true;
          } else {
            downloadedFileAcknowledgement[downloadAcknowledgement.transferId] =
                {formatAtsign(atKey.sharedBy): true};
          }
        }
      } catch (e) {
        print('error in getFileDownloadedAcknowledgement : $e');
      }
    });
  }

  getReceivedHistory() async {
    setStatus(RECEIVED_HISTORY, Status.Loading);
    try {
      await getAllFileTransferData();
      sortReceivedNotifications();
      await sortFiles(receivedHistoryLogs);
      populateTabs();
      setStatus(RECEIVED_HISTORY, Status.Done);
    } catch (error) {
      setStatus(RECEIVED_HISTORY, Status.Error);
      setError(RECEIVED_HISTORY, error.toString());
    }
  }

  checkForUpdatedOrNewNotification(String sharedBy, String decodedMsg) async {
    setStatus(UPDATE_RECEIVED_RECORD, Status.Loading);
    FileTransferObject fileTransferObject =
        FileTransferObject.fromJson((jsonDecode(decodedMsg)));
    FileTransfer filesModel =
        convertFiletransferObjectToFileTransfer(fileTransferObject);
    filesModel.sender = sharedBy;

    //check id data with same key already present
    var index = receivedHistoryLogs
        .indexWhere((element) => element.key == fileTransferObject.transferId);
    _initBackendService();
    if (index > -1) {
      receivedHistoryLogs[index] = filesModel;
    } else {
      // showing notification for new recieved file
      switch (app_lifecycle_state) {
        case 'AppLifecycleState.resumed':
        case 'AppLifecycleState.inactive':
        case 'AppLifecycleState.detached':
          await LocalNotificationService()
              .showNotification(sharedBy, 'Download and view the file(s).');
          break;
        case 'AppLifecycleState.paused':
          await LocalNotificationService().showNotification(
              sharedBy, 'Open the app to download and view the file(s).');
          break;
        default:
          await LocalNotificationService()
              .showNotification(sharedBy, 'Download and view the file(s).');
      }
      await addToReceiveFileHistory(sharedBy, filesModel);
    }
    setStatus(UPDATE_RECEIVED_RECORD, Status.Done);
  }

  updateDownloadAcknowledgement(
      DownloadAcknowledgement downloadAcknowledgement, String sharedBy) async {
    var index = sentHistory.indexWhere((element) =>
        element.fileDetails.key == downloadAcknowledgement.transferId);
    if (index > -1) {
      var i = sentHistory[index]
          .sharedWith
          .indexWhere((element) => element.atsign == sharedBy);
      sentHistory[index].sharedWith[i].isFileDownloaded = true;
      await updateFileHistoryDetail(sentHistory[index]);
    }
  }

  void _initBackendService() async {
    SystemChannels.lifecycle.setMessageHandler((msg) {
      print('set message handler');
      state = msg;
      debugPrint('SystemChannels=> $msg');
      app_lifecycle_state = msg;

      return null;
    });
  }

  addToReceiveFileHistory(String sharedBy, FileTransfer filesModel,
      {bool isUpdate = false}) async {
    setStatus(ADD_RECEIVED_FILE, Status.Loading);
    filesModel.sender = sharedBy;

    if (filesModel.isUpdate) {
      int index = receivedHistoryLogs
          .indexWhere((element) => element?.key?.contains(filesModel.key));
      if (index > -1) {
        receivedHistoryLogs[index] = filesModel;
      }
    } else {
      receivedHistoryNew.insert(0, filesModel);
      receivedHistoryLogs.insert(0, filesModel);
    }

    await sortFiles(receivedHistoryLogs);
    await populateTabs();
    setStatus(ADD_RECEIVED_FILE, Status.Done);
  }

  getAllFileTransferData() async {
    setStatus(GET_ALL_FILE_DATA, Status.Loading);
    List<FileTransfer> tempReceivedHistoryLogs = [];

    List<String> fileTransferResponse =
        await backendService.atClientInstance.getKeys(
      regex: MixedConstants.FILE_TRANSFER_KEY,
    );

    fileTransferResponse.retainWhere((element) =>
        !element.contains(MixedConstants.FILE_TRANSFER_ACKNOWLEDGEMENT));

    await Future.forEach(fileTransferResponse, (key) async {
      if (key.contains('cached') && !checkRegexFromBlockedAtsign(key)) {
        AtKey atKey = AtKey.fromString(key);

        AtValue atvalue = await backendService.atClientInstance
            .get(atKey)
            // ignore: return_of_invalid_type_from_catch_error
            .catchError((e) => print(
                "error in getting atValue in getAllFileTransferData : $e"));

        if (atvalue != null && atvalue.value != null) {
          try {
            FileTransferObject fileTransferObject =
                FileTransferObject.fromJson(jsonDecode(atvalue.value));
            FileTransfer filesModel =
                convertFiletransferObjectToFileTransfer(fileTransferObject);
            filesModel.sender = '@' + key.split('@').last;

            if (filesModel.key != null) {
              tempReceivedHistoryLogs.insert(0, filesModel);
            }
          } catch (e) {
            print('error in getAllFileTransferData file model conversion: $e');
          }
        }
      }
    });

    receivedHistoryLogs = tempReceivedHistoryLogs;

    setStatus(GET_ALL_FILE_DATA, Status.Done);
  }

  sortFiles(List<FileTransfer> filesList) async {
    try {
      setStatus(SORT_FILES, Status.Loading);
      receivedAudio = [];
      receivedApk = [];
      receivedDocument = [];
      receivedPhotos = [];
      receivedVideos = [];
      receivedUnknown = [];
      recentFile = [];
      await Future.forEach(filesList, (fileData) async {
        await Future.forEach(fileData.files, (file) async {
          String fileExtension = file.name.split('.').last;
          FilesDetail fileDetail = FilesDetail(
            fileName: file.name,
            filePath: BackendService.getInstance().downloadDirectory.path +
                '/${file.name}',
            size: double.parse(file.size.toString()),
            date: fileData.date.toLocal().toString(),
            type: file.name.split('.').last,
            contactName: fileData.sender,
          );

          // check if file exists
          File tempFile = File(fileDetail.filePath);
          bool isFileDownloaded = await tempFile.exists();

          if (isFileDownloaded) {
            if (FileTypes.AUDIO_TYPES.contains(fileExtension)) {
              int index = receivedAudio.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                receivedAudio.add(fileDetail);
              }
            } else if (FileTypes.VIDEO_TYPES.contains(fileExtension)) {
              int index = receivedVideos.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                receivedVideos.add(fileDetail);
              }
            } else if (FileTypes.IMAGE_TYPES.contains(fileExtension)) {
              int index = receivedPhotos.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                // checking is photo is downloaded or not
                //if photo is downloaded then only it's shown in my files screen
                File file = File(fileDetail.filePath);
                bool isFileDownloaded = await file.exists();

                if (isFileDownloaded) {
                  receivedPhotos.add(fileDetail);
                }
              }
            } else if (FileTypes.TEXT_TYPES.contains(fileExtension) ||
                FileTypes.PDF_TYPES.contains(fileExtension) ||
                FileTypes.WORD_TYPES.contains(fileExtension) ||
                FileTypes.EXEL_TYPES.contains(fileExtension)) {
              int index = receivedDocument.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                receivedDocument.add(fileDetail);
              }
            } else if (FileTypes.APK_TYPES.contains(fileExtension)) {
              int index = receivedApk.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                receivedApk.add(fileDetail);
              }
            } else {
              int index = receivedUnknown.indexWhere(
                  (element) => element.fileName == fileDetail.fileName);
              if (index == -1) {
                receivedUnknown.add(fileDetail);
              }
            }
          }
        });
      });
      getrecentHistoryFiles();
      setStatus(SORT_FILES, Status.Done);
    } catch (e) {
      setError(SORT_FILES, e.toString());
    }
  }

  getrecentHistoryFiles() async {
    // finding last 15 received files data for recent tab
    setStatus(RECENT_HISTORY, Status.Loading);
    try {
      var lastTenFilesData = receivedHistoryLogs.sublist(
          0, receivedHistoryLogs.length > 15 ? 15 : receivedHistoryLogs.length);

      await Future.forEach(lastTenFilesData, (fileData) async {
        await Future.forEach(fileData.files, (FileData file) async {
          FilesDetail fileDetail = FilesDetail(
            fileName: file.name,
            filePath: BackendService.getInstance().downloadDirectory.path +
                '/${file.name}',
            size: double.parse(file.size.toString()),
            date: fileData.date.toLocal().toString(),
            type: file.name.split('.').last,
            contactName: fileData.sender,
          );

          File tempFile = File(fileDetail.filePath);
          bool isFileDownloaded = await tempFile.exists();
          int index = recentFile
              .indexWhere((element) => element.fileName == fileDetail.fileName);

          if (isFileDownloaded && index == -1) {
            recentFile.add(fileDetail);
          }
        });
      });
      setStatus(RECENT_HISTORY, Status.Done);
    } catch (e) {
      setStatus(RECENT_HISTORY, Status.Error);
    }

    print('recentFile data : ${recentFile.length}');
  }

  populateTabs() {
    tabs = [Recents()];
    tabNames = ['Recents'];
    try {
      setStatus(POPULATE_TABS, Status.Loading);

      if (receivedApk.isNotEmpty) {
        if (!tabs.contains(APK) || !tabs.contains(APK())) {
          tabs.add(APK());
          tabNames.add('APK');
        }
      }
      if (receivedAudio.isNotEmpty) {
        if (!tabs.contains(Audios) || !tabs.contains(Audios())) {
          tabs.add(Audios());
          tabNames.add('Audios');
        }
      }
      if (receivedDocument.isNotEmpty) {
        if (!tabs.contains(Documents) || !tabs.contains(Documents())) {
          tabs.add(Documents());
          tabNames.add('Documents');
        }
      }
      if (receivedPhotos.isNotEmpty) {
        if (!tabs.contains(Photos) || !tabs.contains(Photos())) {
          tabs.add(Photos());
          tabNames.add('Photos');
        }
      }
      if (receivedVideos.isNotEmpty) {
        if (!tabs.contains(Videos) || !tabs.contains(Videos())) {
          tabs.add(Videos());
          tabNames.add('Videos');
        }
      }
      if (receivedUnknown.isNotEmpty) {
        if (!tabs.contains(Unknowns()) || !tabs.contains(Unknowns())) {
          tabs.add(Unknowns());
          tabNames.add('Unknowns');
        }
      }

      print('tabs populated: ${tabs}');

      setStatus(POPULATE_TABS, Status.Done);
    } catch (e) {
      setError(POPULATE_TABS, e.toString());
    }
  }

  sortReceivedNotifications() {
    receivedHistoryLogs.sort((a, b) => b.date.compareTo(a.date));
  }

  sortByName(List<FilesDetail> list) {
    try {
      setStatus(SORT_LIST, Status.Loading);
      list.sort((a, b) => a.fileName.compareTo(b.fileName));

      setStatus(SORT_LIST, Status.Done);
    } catch (e) {
      setError(SORT_LIST, e.toString());
    }
  }

  sortBySize(List<FilesDetail> list) {
    try {
      setStatus(SORT_LIST, Status.Loading);
      list.sort((a, b) => a.size.compareTo(b.size));

      setStatus(SORT_LIST, Status.Done);
    } catch (e) {
      setError(SORT_LIST, e.toString());
    }
  }

  sortByType(List<FilesDetail> list) {
    try {
      setStatus(SORT_LIST, Status.Loading);
      list.sort((a, b) =>
          a.fileName.split('.').last.compareTo(b.fileName.split('.').last));

      setStatus(SORT_LIST, Status.Done);
    } catch (e) {
      setError(SORT_LIST, e.toString());
    }
  }

  sortByDate(List<FilesDetail> list) {
    try {
      setStatus(SORT_LIST, Status.Loading);

      list.sort(
          (a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));
      setStatus(SORT_LIST, Status.Done);
    } catch (e) {
      setError(SORT_LIST, e.toString());
    }
  }

  bool checkRegexFromBlockedAtsign(String regex) {
    bool isBlocked = false;
    String atsign = regex.split('@')[regex.split('@').length - 1];

    ContactService().blockContactList.forEach((element) {
      if (element.atSign == '@${atsign}') {
        isBlocked = true;
      }
    });
    return isBlocked;
  }

  FileTransfer convertFiletransferObjectToFileTransfer(
      FileTransferObject fileTransferObject) {
    List<FileData> files = [];
    fileTransferObject.fileStatus.forEach((fileDetail) {
      files.add(FileData(
          name: fileDetail.fileName,
          size: fileDetail.size,
          isUploaded: fileDetail.isUploaded));
    });

    return FileTransfer(
      url: fileTransferObject.fileUrl,
      files: files,
      date: fileTransferObject.date,
      key: fileTransferObject.transferId,
    );
  }

  updateFileSendingStatus(
      {bool isUploading, bool isUploaded, String id, String filename}) {
    var index =
        sentHistory.indexWhere((element) => element.fileDetails.key == id);
    if (index > -1) {
      var fileIndex = sentHistory[index]
          .fileDetails
          .files
          .indexWhere((element) => element.name == filename);

      // as of now operating is only used to determine whether file is being uploaded or not
      // As per requirement it can be used to determine whether notification is being sent or not.
      sentHistory[index].isOperating = isUploading;

      if (fileIndex > -1) {
        sentHistory[index].fileDetails.files[fileIndex].isUploading =
            isUploading;
        sentHistory[index].fileDetails.files[fileIndex].isUploaded = isUploaded;
      }
    }
    notifyListeners();
  }

  FileHistory convertFileTransferObjectToFileHistory(
      FileTransferObject fileTransferObject,
      List<String> sharedWithAtsigns,
      Map<String, FileTransferObject> fileShareResult) {
    List<FileData> files = [];
    var sthareStatus = <ShareStatus>[];

    fileTransferObject.fileStatus.forEach((fileDetail) {
      files.add(FileData(
          name: fileDetail.fileName,
          size: fileDetail.size,
          isUploaded: fileDetail.isUploaded));
    });

    FileTransfer fileTransfer = FileTransfer(
      key: fileTransferObject.transferId,
      date: fileTransferObject.date,
      files: files,
      url: fileTransferObject.fileUrl,
    );

    sharedWithAtsigns.forEach((atsign) {
      sthareStatus
          .add(ShareStatus(atsign, fileShareResult[atsign].sharedStatus));
    });

    return FileHistory(
        fileTransfer, sthareStatus, HistoryType.send, fileTransferObject);
  }

  downloadFiles(String transferId, String sharedBy, bool isWidgetOpen) async {
    var index =
        receivedHistoryLogs.indexWhere((element) => element.key == transferId);
    try {
      if (index > -1) {
        receivedHistoryLogs[index].isDownloading = true;
        receivedHistoryLogs[index].isWidgetOpen = isWidgetOpen;
      }
      notifyListeners();

      var files = await backendService.atClientInstance
          .downloadFile(transferId, sharedBy);
      receivedHistoryLogs[index].isDownloading = false;

      Provider.of<FileDownloadChecker>(NavService.navKey.currentContext,
              listen: false)
          .checkForUndownloadedFiles();

      if (files is List<File>) {
        await sortFiles(receivedHistoryLogs);
        populateTabs();
        setStatus(DOWNLOAD_FILE, Status.Done);
        return true;
      } else {
        setStatus(DOWNLOAD_FILE, Status.Done);
        return false;
      }
    } catch (e) {
      print('error in downloading file: $e');
      receivedHistoryLogs[index].isDownloading = false;
      setStatus(DOWNLOAD_FILE, Status.Error);
      return false;
    }
  }

  downloadSingleFile(
    String transferId,
    String sharedBy,
    bool isWidgetOpen,
    String fileName,
  ) async {
    var index =
        receivedHistoryLogs.indexWhere((element) => element.key == transferId);
    var _fileIndex = receivedHistoryLogs[index]
        .files
        .indexWhere((_file) => _file.name == fileName);
    try {
      if ((index > -1) && (_fileIndex > -1)) {
        receivedHistoryLogs[index].files[_fileIndex].isDownloading = true;
        receivedHistoryLogs[index].isWidgetOpen = isWidgetOpen;
      }
      notifyListeners();

      var files =
          await _downloadSingleFileFromWeb(transferId, sharedBy, fileName);
      receivedHistoryLogs[index].files[_fileIndex].isDownloading = false;

      Provider.of<FileDownloadChecker>(NavService.navKey.currentContext,
              listen: false)
          .checkForUndownloadedFiles();

      if (files is List<File>) {
        await sortFiles(receivedHistoryLogs);
        populateTabs();
        setStatus(DOWNLOAD_FILE, Status.Done);
        return true;
      } else {
        setStatus(DOWNLOAD_FILE, Status.Done);
        return false;
      }
    } catch (e) {
      print('error in downloading file: $e');
      receivedHistoryLogs[index].isDownloading = false;
      receivedHistoryLogs[index].files[_fileIndex].isDownloading = false;
      setStatus(DOWNLOAD_FILE, Status.Error);
      return false;
    }
  }

  Future<List<File>> _downloadSingleFileFromWeb(
      String transferId, String sharedByAtSign, String fileName,
      {String downloadPath}) async {
    downloadPath ??=
        BackendService.getInstance().atClientPreference.downloadPath;
    if (downloadPath == null) {
      throw Exception('downloadPath not found');
    }
    var atKey = AtKey()
      ..key = transferId
      ..sharedBy = sharedByAtSign;
    var result =
        await AtClientManager.getInstance().atClient.get(atKey).catchError((e) {
      print('error in _downloadSingleFileFromWeb : $e');
    });

    if (result == null) {
      return [];
    }
    FileTransferObject fileTransferObject;
    try {
      var _jsonData = jsonDecode(result.value);
      _jsonData['fileUrl'] = _jsonData['fileUrl'].replaceFirst('/archive', '');
      _jsonData['fileUrl'] = _jsonData['fileUrl'].replaceFirst('/zip', '');
      _jsonData['fileUrl'] = _jsonData['fileUrl'] + '/$fileName';

      fileTransferObject = FileTransferObject.fromJson(_jsonData);
      print('fileTransferObject.fileUrl ${fileTransferObject.fileUrl}');
    } on Exception catch (e) {
      throw Exception('json decode exception in download file ${e.toString()}');
    }
    var downloadedFiles = <File>[];
    var fileDownloadReponse = await _downloadSingleFromFileBin(
        fileTransferObject, downloadPath, fileName);
    if (fileDownloadReponse.isError) {
      throw Exception('download fail');
    }
    var encryptedFileList = Directory(fileDownloadReponse.filePath).listSync();
    try {
      for (var encryptedFile in encryptedFileList) {
        var decryptedFile = EncryptionService().decryptFile(
            File(encryptedFile.path).readAsBytesSync(),
            fileTransferObject.fileEncryptionKey);
        var downloadedFile =
            File(downloadPath + '/' + encryptedFile.path.split('/').last);
        downloadedFile.writeAsBytesSync(decryptedFile);
        downloadedFiles.add(downloadedFile);
      }
      // deleting temp directory
      Directory(fileDownloadReponse.filePath).deleteSync(recursive: true);
      return downloadedFiles;
    } catch (e) {
      print('error in downloadFile: $e');
      return [];
    }
  }

  Future<FileDownloadResponse> _downloadSingleFromFileBin(
      FileTransferObject fileTransferObject,
      String downloadPath,
      String fileName) async {
    try {
      var response = await http.get(Uri.parse(fileTransferObject.fileUrl));
      if (response.statusCode != 200) {
        return FileDownloadResponse(
            isError: true, errorMsg: 'error in fetching data');
      }
      var tempDirectory =
          await Directory(downloadPath).createTemp('encrypted-files');
      var encryptedFile = File(tempDirectory.path + '/' + fileName);
      encryptedFile.writeAsBytesSync(response.bodyBytes);

      return FileDownloadResponse(filePath: tempDirectory.path);
    } catch (e) {
      print('error in downloading file: $e');
      return FileDownloadResponse(isError: true, errorMsg: e.toString());
    }
  }

  updateSendingNotificationStatus(
      String transferId, String atsign, bool isSending) {
    var index = sentHistory.indexWhere(
        (element) => element.fileTransferObject.transferId == transferId);
    if (index != -1) {
      var atsignIndex = sentHistory[index]
          .sharedWith
          .indexWhere((element) => element.atsign == atsign);
      if (atsignIndex != -1) {
        sentHistory[index].sharedWith[atsignIndex].isSendingNotification =
            isSending;
      }
    }
    notifyListeners();
  }

  Future<bool> sendFileDownloadAcknowledgement(
      FileTransfer fileTransfer) async {
    var downloadAcknowledgement =
        DownloadAcknowledgement(true, fileTransfer.key);

    AtKey atKey = AtKey()
      ..metadata = Metadata()
      ..metadata.ttr = -1
      ..metadata.ccd = true
      ..key = MixedConstants.FILE_TRANSFER_ACKNOWLEDGEMENT + fileTransfer.key
      ..metadata.ttl = 518400000
      ..sharedWith = fileTransfer.sender;
    try {
      var notificationResult =
          await AtClientManager.getInstance().notificationService.notify(
                NotificationParams.forUpdate(
                  atKey,
                  value: jsonEncode(downloadAcknowledgement.toJson()),
                ),
              );

      if (notificationResult.notificationStatusEnum ==
          NotificationStatusEnum.delivered) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  bool compareAtSign(String atsign1, String atsign2) {
    if (atsign1[0] != '@') {
      atsign1 = '@' + atsign1;
    }
    if (atsign2[0] != '@') {
      atsign2 = '@' + atsign2;
    }

    return atsign1.toLowerCase() == atsign2.toLowerCase() ? true : false;
  }

  String formatAtsign(String atsign) {
    if (atsign[0] != '@') {
      atsign = '@' + atsign;
    }
    return atsign;
  }

  // save file in gallery function is not in use as of now.
  // saveFilesInGallery(List<File> files) async {
  //   for (var file in files) {
  //     if (FileTypes.IMAGE_TYPES.contains(file.path.split('.').last) ||
  //         FileTypes.VIDEO_TYPES.contains(file.path.split('.').last)) {
  //       // saving image,video in gallery.
  //       await ImageGallerySaver.saveFile(file.path);
  //     }
  //   }
  // }
}
