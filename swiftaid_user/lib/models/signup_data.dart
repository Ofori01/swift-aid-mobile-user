class SignupData {
  String fullName;
  String phoneNumber;
  String password;
  String confirmPassword;
  String ghanaCardNumber;
  String email;
  String? ghanaCardFrontImagePath;
  String? ghanaCardBackImagePath;

  SignupData({
    this.fullName = '',
    this.phoneNumber = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.ghanaCardNumber = '',
    this.ghanaCardFrontImagePath,
    this.ghanaCardBackImagePath,
  });
}
