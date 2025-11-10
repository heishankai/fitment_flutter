import 'package:fitment_flutter/dao/login_dao.dart';

getHeaders() {
  Map<String, String> headers = {};
  headers['Content-Type'] = 'application/json';
  headers['Accept'] = 'application/json';

  // 如果 token 存在，则添加到 headers
  if (LoginDao.getToken() != null && LoginDao.getToken()!.isNotEmpty) {
    headers['Authorization'] = 'Bearer ${LoginDao.getToken()}';
  }
  return headers;
}
