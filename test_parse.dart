import 'dart:convert';
import 'lib/core/models/paged_result.dart';
import 'lib/features/user_management/models/user.dart';

void main() {
  String jsonStr = '''
  {
    "items":[{"userId":14,"username":"duykhanhadmin","fullName":"Bui Duy Khanh","email":"duykhanh2004tcmc@gmail.com","phone":"0344051851","roleId":2,"roleName":"Chain Director","branchId":null,"branchName":null,"isActive":true,"createdAt":"2026-07-13T14:48:51.5705366"},{"userId":13,"username":"warehouse2","fullName":"Thủ Kho 2 test edit","email":"thukho2@gmail.com","phone":"0344051852","roleId":5,"roleName":"Warehouse Staff","branchId":null,"branchName":null,"isActive":true,"createdAt":"2026-07-10T15:28:53.2657118"}],
    "totalCount":14,"pageNumber":1,"pageSize":5,"totalPages":3
  }
  ''';
  var decoded = jsonDecode(jsonStr);
  try {
    var result = PagedResult<User>.fromJson(decoded, (json) => User.fromJson(json));
    print("Success: ${result.items.length}");
  } catch(e, stacktrace) {
    print("Error: $e");
    print(stacktrace);
  }
}
