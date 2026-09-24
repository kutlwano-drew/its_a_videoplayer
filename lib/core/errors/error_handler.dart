import 'app_error.dart';
import 'error_messages.dart';

class ErrorHandler {
  static String message(Object error, {AppErrorCode code = AppErrorCode.unknown}) {
    return friendlyErrorMessage(
      AppError(code: code, message: error.toString()),
    );
  }
}
