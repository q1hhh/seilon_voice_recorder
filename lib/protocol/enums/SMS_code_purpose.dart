// 短信验证码用途： 1.注册；2.登录；3.找回密码；4.更改手机号 "6:App注销用户"
enum SMSCodePurpose {  
  register(1),  
  login(2),  
  resetPassword(3),  
  changePhoneNumber(4),  
  appUnregisterUser(6);  
  
  final int code;  
  
  const SMSCodePurpose(this.code);  
    
  static int getCode(SMSCodePurpose purpose) => purpose.code;  
}  
  
 