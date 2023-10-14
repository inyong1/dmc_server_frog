
// ignore_for_file: public_member_api_docs
/// Default response
class BaseResponse {
  BaseResponse({
    this.success = false,
    this.message = 'Terjadi kesalahan',
  });

  final bool success;
  final String message;

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
      };
}
