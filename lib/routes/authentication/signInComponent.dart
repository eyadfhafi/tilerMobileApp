import 'dart:io';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tiler_app/bloc/schedule/schedule_bloc.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tiler_app/bloc/scheduleSummary/schedule_summary_bloc.dart';
import 'package:tiler_app/components/notification_overlay.dart';
import 'package:tiler_app/data/request/TilerError.dart';
import 'package:tiler_app/routes/authenticatedUser/welcomeScreen.dart';
import 'package:tiler_app/services/api/userPasswordAuthenticationData.dart';
import 'package:tiler_app/services/localAuthentication.dart';
import '../../services/api/authorization.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:tiler_app/services/analyticsSignal.dart';

import '../../services/api/thirdPartyAuthResult.dart';
import '../../styles.dart';
import '../../util.dart';

class SignInComponent extends StatefulWidget {
  @override
  SignInComponentState createState() => SignInComponentState();
}

// Define a corresponding State class.
// This class holds data related to the Form.
class SignInComponentState extends State<SignInComponent>
    with TickerProviderStateMixin {
  // Create a text controller. Later, use it to retrieve the
  // current value of the TextField.
  final _formKey = GlobalKey<FormState>();
  final userNameEditingController = TextEditingController();
  final passwordEditingController = TextEditingController();
  final emailEditingController = TextEditingController();
  final confirmPasswordEditingController = TextEditingController();

  final FocusNode _passwordFocusNode = FocusNode();
  bool isPassWordFieldFocused = false;

  final FocusNode _confirmPasswordFocusNode = FocusNode();
  bool isConfirmPassWordFieldFocused = false;

  late AnimationController signinInAnimationController;

  bool isRegistrationScreen = false;
  bool isForgetPasswordScreen = false;
  final double registrationContainerHeight = 550;
  final double signInContainerHeight = 400;
  final double forgotPasswordContainerHeight = 300;

  final double registrationContainerButtonHeight = 300;
  final double signInContainerButtonHeight = 175;
  final double forgotPasswordContainerButtonHeight = 100;

  late double credentialManagerHeight = 400;
  double credentialButtonHeight = 175;
  bool isPendingSigning = false;
  bool isSuccessfulSignin = false;
  bool isPendingRegistration = false;
  bool isSuccessfulRegistration = false;
  bool isPendingResetPassword = false;
  bool isGoogleSignInEnabled = false;
  bool _isPasswordVisible = false;
  bool shouldHideButtons = false;

  // Registration Password Validator Rules
  bool isMinLength = false;
  bool isUpperCase = false;
  bool isLowerCase = false;
  bool isNumber = false;
  bool isSpecialChar = false;
  bool isPasswordValid = false;
  bool isPasswordsMatch = false;

  bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  bool hasUppercase(String value) {
    return value.contains(RegExp(r'[A-Z]'));
  }

  bool hasLowercase(String value) {
    return value.contains(RegExp(r'[a-z]'));
  }

  bool hasNumber(String value) {
    return value.contains(RegExp(r'[0-9]'));
  }

  bool hasSpecialCharacter(String value) {
    return value.contains(RegExp(r'[^a-zA-Z0-9]'));
  }

  bool passwordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  bool checkIfPasswordValid() {
    return isMinLength &&
        isUpperCase &&
        isLowerCase &&
        isNumber &&
        isSpecialChar;
  }

  late final AuthorizationApi authApi;
  NotificationOverlayMessage notificationOverlayMessage =
      NotificationOverlayMessage();
  final inputFieldFillColor = Color.fromRGBO(255, 255, 255, .75);

  @override
  void initState() {
    super.initState();
    authApi = AuthorizationApi(
      getContextCallBack: () => context,
    );
    signinInAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    isGoogleSignInEnabled = !Platform.isIOS;
    if (Platform.isIOS) {
      authApi.statusSupport().then((value) {
        String versionKey = "version";
        String authResult = "315";
        if (value != null &&
            value.containsKey(versionKey) &&
            value[versionKey] != null) {
          for (var versions in value[versionKey]) {
            if (versions == authResult) {
              setState(() {
                isGoogleSignInEnabled = true;
              });
            }
          }
        }
      });
    }
    credentialManagerHeight = signInContainerHeight;
    credentialButtonHeight = signInContainerButtonHeight;

    _onPasswordFocusChange();
    _onConfirmPasswordFocusChange();
  }

  void _onPasswordFocusChange() {
    _passwordFocusNode.addListener(() {
      setState(() {
        if (_passwordFocusNode.hasFocus) {
          isPassWordFieldFocused = true;
        } else {
          isPassWordFieldFocused = false;
        }
      });
    });
  }

  void _onConfirmPasswordFocusChange() {
    _confirmPasswordFocusNode.addListener(() {
      setState(() {
        if (_confirmPasswordFocusNode.hasFocus) {
          isConfirmPassWordFieldFocused = true;
        } else {
          isConfirmPassWordFieldFocused = false;
        }
      });
    });
  }

  void hideButtonsTemporarily({int duration = 3}) {
    if (!mounted) return;
    setState(() {
      shouldHideButtons = true;
    });
    Future.delayed(Duration(seconds: duration), () {
      if (!mounted) return;
      setState(() {
        shouldHideButtons = false;
      });
    });
  }

  void showMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  void showErrorMessage(String message) {
    Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.SNACKBAR,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.black45,
        textColor: Colors.red,
        fontSize: 16.0);
  }

  void userNamePasswordSignIn() async {
    if (_formKey.currentState!.validate()) {
      AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_INITIATED');
      showMessage(AppLocalizations.of(context)!.signingIn);
      setState(() {
        isPendingSigning = true;
      });
      SystemChannels.textInput.invokeMethod('TextInput.hide');
      try {
        UserPasswordAuthenticationData authenticationData =
            await UserPasswordAuthenticationData.getAuthenticationInfo(
                userNameEditingController.text, passwordEditingController.text);

        setState(() {
          isPendingSigning = false;
        });
        String isValidSignIn = "Authentication data is valid:" +
            authenticationData.isValid.toString();
        isSuccessfulSignin = authenticationData.isValid;
        if (!authenticationData.isValid) {
          AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_FAILED');
          if (authenticationData.errorMessage != null) {
            hideButtonsTemporarily();
            notificationOverlayMessage.showToast(
              context,
              authenticationData.errorMessage!,
              NotificationOverlayMessageType.error,
            );
            return;
          }
        }
        AnalysticsSignal.send('TILER_SIGNIN_USERNAMEPASSWORD_SUCCESS');
        setState(() {
          isPendingSigning = false;
        });
        TextInput.finishAutofillContext();
        Authentication localAuthentication = new Authentication();
        await localAuthentication.saveCredentials(authenticationData);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.read<ScheduleBloc>().add(LogInScheduleEvent(
              getContextCallBack: () => context,
            ));
        bool nextPage = await Utility.checkOnboardingStatus();

        context.read<ScheduleBloc>().add(GetScheduleEvent(
            scheduleTimeline: Utility.initialScheduleTimeline,
            isAlreadyLoaded: false,
            previousSubEvents: []));
        this.context.read<ScheduleSummaryBloc>().add(
              GetScheduleDaySummaryEvent(
                  timeline: Utility.initialScheduleTimeline),
            );
        print("is sign in valid" + isValidSignIn.toString());
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              welcomeType: WelcomeType.login,
              firstName: (authenticationData.username != null &&
                      authenticationData.username!.isNotEmpty)
                  ? authenticationData.username!
                  : "",
            ),
          ),
        );
        setState(() {
          isPendingSigning = false;
        });
      } catch (e) {
        if (TilerError.isUnexpectedCharacter(e)) {
          setState(() {
            isPendingSigning = false;
          });
          hideButtonsTemporarily();
          notificationOverlayMessage.showToast(
            context,
            AppLocalizations.of(context)!.invalidUsernameOrPassword,
            NotificationOverlayMessageType.error,
          );
        }
      }
    }
  }

  bool _keyboardIsVisible() {
    return MediaQuery.of(context).viewInsets.bottom != 0;
  }

  void registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          isPendingRegistration = true;
        });
        SystemChannels.textInput.invokeMethod('TextInput.hide');
        showMessage(AppLocalizations.of(context)!.registeringUser);
        AuthorizationApi authorization = new AuthorizationApi(
          getContextCallBack: () => context,
        );
        UserPasswordAuthenticationData authenticationData =
            await authorization.registerUser(
                emailEditingController.text,
                passwordEditingController.text,
                userNameEditingController.text,
                confirmPasswordEditingController.text,
                null);
        setState(() {
          isPendingRegistration = false;
        });
        String isValidSignIn = "Authentication data is valid:" +
            authenticationData.isValid.toString();
        isSuccessfulRegistration = authenticationData.isValid;
        if (!authenticationData.isValid) {
          if (authenticationData.errorMessage != null) {
            hideButtonsTemporarily();
            notificationOverlayMessage.showToast(
              context,
              authenticationData.errorMessage!,
              NotificationOverlayMessageType.error,
            );
            return;
          }
        }
        Authentication localAuthentication = new Authentication();
        await localAuthentication.saveCredentials(authenticationData);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        bool nextPage = await Utility.checkOnboardingStatus();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              welcomeType: WelcomeType.register,
              firstName: (authenticationData.username != null &&
                      authenticationData.username!.isNotEmpty)
                  ? authenticationData.username!
                  : "",
            ),
          ),
        );

        context.read<ScheduleBloc>().add(GetScheduleEvent(
            scheduleTimeline: Utility.initialScheduleTimeline,
            isAlreadyLoaded: false,
            previousSubEvents: []));

        print(isValidSignIn);
      } catch (e) {
        setState(() {
          isPendingRegistration = false;
        });
        if (TilerError.isUnexpectedCharacter(e)) {
          hideButtonsTemporarily();
          notificationOverlayMessage.showToast(
            context,
            AppLocalizations.of(context)!.issuesConnectingToTiler,
            NotificationOverlayMessageType.error,
          );
          setState(() {
            isPendingRegistration = false;
          });
        }
      }
    }
  }

  void forgetPassword() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          isPendingResetPassword = true;
        });
        AnalysticsSignal.send('FORGOT_PASSWORD_INITIATED');
        showMessage(AppLocalizations.of(context)!.forgetPassword);
        var result = await AuthorizationApi.sendForgotPasswordRequest(
            emailEditingController.text);
        if (result.error.code == "0") {
          AnalysticsSignal.send('FORGOT_PASSWORD_SUCCESS');
          hideButtonsTemporarily();
          notificationOverlayMessage.showToast(
            context,
            result.error.message,
            NotificationOverlayMessageType.error,
          );
          Future.delayed(Duration(seconds: 2), () {
            setState(() {
              setAsSignInScreen();
            });
          });
        } else {
          AnalysticsSignal.send('FORGOT_PASSWORD_ERROR');
          hideButtonsTemporarily();
          notificationOverlayMessage.showToast(
            context,
            result.error.message,
            NotificationOverlayMessageType.error,
          );
        }
      } catch (e) {
        AnalysticsSignal.send('FORGOT_PASSWORD_SERVER_ERROR');
        hideButtonsTemporarily();
        notificationOverlayMessage.showToast(
          context,
          "Error: $e",
          NotificationOverlayMessageType.error,
        );
      } finally {
        Future.delayed(Duration(seconds: 2), () {
          setState(() {
            isPendingResetPassword = false;
          });
        });
      }
    }
  }

  void setAsForgetPasswordScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() {
      isForgetPasswordScreen = true;
      isRegistrationScreen = false;
      credentialManagerHeight = forgotPasswordContainerHeight;
      credentialButtonHeight = forgotPasswordContainerButtonHeight;
    });
  }

  void setAsRegistrationScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() {
      isRegistrationScreen = true;
      credentialManagerHeight = registrationContainerHeight;
      credentialButtonHeight = registrationContainerButtonHeight;
      isMinLength = false;
      isUpperCase = false;
      isLowerCase = false;
      isNumber = false;
      isSpecialChar = false;
    });
  }

  void setAsSignInScreen() {
    userNameEditingController.clear();
    passwordEditingController.clear();
    emailEditingController.clear();
    confirmPasswordEditingController.clear();
    setState(() {
      isRegistrationScreen = false;
      isForgetPasswordScreen = false;
      credentialManagerHeight = signInContainerHeight;
      credentialButtonHeight = signInContainerButtonHeight;
    });
  }

  Widget createSignInPendingComponent(String message) {
    return Container(
        child: Center(
            child: FadeTransition(
      opacity: CurvedAnimation(
        parent: signinInAnimationController,
        curve: Curves.easeIn,
      ),
      child: Row(children: [
        CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
        Container(
            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: Text(
              message,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ))
      ]),
    )));
  }

  String validatorCondition(String condition, bool value) {
    if (value) {
      return "";
    } else {
      return condition;
    }
  }

  Widget spacer(double height) {
    return SizedBox(
      height: height,
    );
  }

  Future signInToGoogle() async {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    AnalysticsSignal.send('GOOGLE_SIGNUP_INITIALIZE');
    setState(() {
      isPendingSigning = true;
    });
    AuthorizationApi authorizationApi = AuthorizationApi(
      getContextCallBack: () => context,
    );
    AuthResult? authenticationData =
        await authorizationApi.signInToGoogle().then((value) {
      AnalysticsSignal.send('GOOGLE_SIGNUP_SUCCESSFUL');
      return value;
    }).catchError((onError) {
      setState(() {
        isPendingSigning = false;
      });
      AnalysticsSignal.send('GOOGLE_SIGNUP_FAILED');
      hideButtonsTemporarily();
      notificationOverlayMessage.showToast(
        context,
        onError.errorMessage,
        NotificationOverlayMessageType.error,
      );
      return null;
    });

    if (authenticationData != null) {
      if (authenticationData.authData.isValid) {
        Authentication localAuthentication = new Authentication();
        await localAuthentication.saveCredentials(authenticationData.authData);
        while (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        context.read<ScheduleBloc>().add(LogInScheduleEvent(
              getContextCallBack: () => context,
            ));
        bool nextPage = await Utility.checkOnboardingStatus();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(
              welcomeType: WelcomeType.login,
              firstName: (authenticationData.displayName != null &&
                      authenticationData.displayName.isNotEmpty)
                  ? authenticationData.displayName
                  : "",
            ),
          ),
        );
        context.read<ScheduleBloc>().add(GetScheduleEvent(
            scheduleTimeline: Utility.initialScheduleTimeline,
            isAlreadyLoaded: false,
            previousSubEvents: []));
      }
    }
    setState(() {
      isPendingSigning = false;
    });
  }

  @override
  void dispose() {
    userNameEditingController.dispose();
    passwordEditingController.dispose();
    emailEditingController.dispose();
    confirmPasswordEditingController.dispose();
    signinInAnimationController.dispose();
    notificationOverlayMessage.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    // Function to dynamically calculate height according to screen size
    double calculateSizeByHeight(double value) {
      return height / (height / value);
    }

    List<String> unmetConditions = [];

    if (!isUpperCase) {
      unmetConditions
          .add(AppLocalizations.of(context)!.passwordConditionUppercaseLetters);
    }
    if (!isLowerCase) {
      unmetConditions
          .add(AppLocalizations.of(context)!.passwordConditionLowercaseLetters);
    }
    if (!isNumber) {
      unmetConditions
          .add(AppLocalizations.of(context)!.passwordConditionNumbers);
    }
    if (!isSpecialChar) {
      unmetConditions
          .add(AppLocalizations.of(context)!.passwordConditionSpecialCharacter);
    }

    String formatConditionsList(BuildContext context, List<String> conditions) {
      String separator = AppLocalizations.of(context)!.listSeparator;
      String finalSeparator = AppLocalizations.of(context)!.listFinalSeparator;

      if (conditions.length == 1) {
        return conditions.first;
      } else if (conditions.length == 2) {
        return conditions.join(finalSeparator.trim());
      } else {
        return conditions.sublist(0, conditions.length - 1).join(separator) +
            finalSeparator +
            conditions.last;
      }
    }

    String instructionMessage = '';

    if (!isMinLength || unmetConditions.isNotEmpty) {
      instructionMessage =
          AppLocalizations.of(context)!.passwordCreationMessagePart1;

      if (!isMinLength) {
        instructionMessage +=
            AppLocalizations.of(context)!.passwordConditionMinLength;
      }

      if (unmetConditions.isNotEmpty) {
        if (!isMinLength) {
          instructionMessage +=
              AppLocalizations.of(context)!.passwordCreationMessageIncluding;
        } else {
          // Add "including" without leading comma if min length is met
          instructionMessage += AppLocalizations.of(context)!
              .passwordCreationMessageIncluding
              .trim();
        }

        String conditionsList = formatConditionsList(context, unmetConditions);
        instructionMessage += conditionsList;
      }

      // Ensure the message ends with a period
      if (!instructionMessage.endsWith('.')) {
        instructionMessage += '.';
      }
    }

    var usernameTextField = TextFormField(
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (!isRegistrationScreen) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.fieldIsRequired;
          }
        }
        return null;
      },
      controller: userNameEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newUsername
            : AutofillHints.username
      ],
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.username,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.person),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: inputFieldFillColor,
        border: OutlineInputBorder(
            borderRadius: TileStyles.inputFieldBorderRadius,
            borderSide: BorderSide.none),
      ),
    );

    var emailTextField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.emailIsRequired;
        }
        return null;
      },
      controller: emailEditingController,
      autofillHints: [AutofillHints.email],
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.email,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.email),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        fillColor: inputFieldFillColor,
        border: OutlineInputBorder(
            borderRadius: TileStyles.inputFieldBorderRadius,
            borderSide: BorderSide.none),
      ),
    );

    var passwordTextField = TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return AppLocalizations.of(context)!.passwordIsRequired;
        }

        if (isRegistrationScreen) {
          var minPasswordLength = 6;
          if (value != confirmPasswordEditingController.text) {
            return AppLocalizations.of(context)!.passwordsDontMatch;
          }

          if (value.length < minPasswordLength) {
            return "";
          }
          if (!value.contains(RegExp(r'[A-Z]+'))) {
            return "";
          }
          if (!value.contains(RegExp(r'[a-z]+'))) {
            return "";
          }
          if (!value.contains(RegExp(r'[0-9]+'))) {
            return "";
          }
          if (!value.contains(RegExp(r'[^a-zA-Z0-9]'))) {
            return "";
          }
        }

        return null;
      },
      onChanged: (value) {
        setState(() {
          isMinLength = hasMinLength(value, 6);
          isUpperCase = hasUppercase(value);
          isLowerCase = hasLowercase(value);
          isNumber = hasNumber(value);
          isSpecialChar = hasSpecialCharacter(value);
          isPasswordValid = checkIfPasswordValid();
        });
      },
      focusNode: _passwordFocusNode,
      controller: passwordEditingController,
      autofillHints: [
        this.isRegistrationScreen
            ? AutofillHints.newPassword
            : AutofillHints.password
      ],
      onEditingComplete: () => TextInput.finishAutofillContext(),
      obscureText: !_isPasswordVisible,
      keyboardType: TextInputType.visiblePassword,
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context)!.password,
        filled: true,
        isDense: true,
        prefixIcon: Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
        border: OutlineInputBorder(
            borderRadius: TileStyles.inputFieldBorderRadius,
            borderSide: BorderSide.none),
        fillColor: inputFieldFillColor,
      ),
    );

    var forgetPasswordTextButton = GestureDetector(
      onTap: () => setAsForgetPasswordScreen(),
      child: Container(
        padding: EdgeInsets.only(left: 5),
        alignment: Alignment.centerLeft,
        child: Text(
          AppLocalizations.of(context)!.forgotPasswordBtn,
          style: TextStyle(
              color: Color(0xFF880E4F), decoration: TextDecoration.underline),
        ),
      ),
    );

    var passwordValidatorRules = SizedBox(
      width: MediaQuery.of(context).size.width,
      child: !isPasswordValid
          ? Text(
              instructionMessage,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                fontSize: calculateSizeByHeight(12),
                color: Colors.red,
              ),
            )
          : SizedBox.shrink(),
    );

    var confirmPasswordValidatorRules = SizedBox(
      width: MediaQuery.of(context).size.width,
      child: !isPasswordsMatch
          ? Text(
              AppLocalizations.of(context)!.passwordsDontMatch,
              textAlign: TextAlign.start,
              style: TextStyle(
                fontFamily: TileStyles.rubikFontName,
                fontWeight: FontWeight.w300,
                fontSize: calculateSizeByHeight(12),
                color: Colors.red,
              ),
            )
          : SizedBox.shrink(),
    );

    List<Widget> textFields = [
      spacer(20),
      usernameTextField,
      spacer(20),
      passwordTextField,
      spacer(10),
      forgetPasswordTextButton,
      spacer(40),
    ];

    var signUpButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.person_add),
        label: Text(AppLocalizations.of(context)!.signUp),
        onPressed: setAsRegistrationScreen,
      ),
    );

    var signInButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.arrow_forward),
        label: Text(AppLocalizations.of(context)!.signIn),
        onPressed: userNamePasswordSignIn,
      ),
    );

    var googleSignInButton = isGoogleSignInEnabled
        ? SizedBox(
            width: 200,
            child: ElevatedButton.icon(
                onPressed: signInToGoogle,
                icon: FaIcon(
                  FontAwesomeIcons.google,
                  color: Colors.white,
                ),
                label: Text(AppLocalizations.of(context)!.signUpWithGoogle)),
          )
        : SizedBox.shrink();

    var backToSignInButton = SizedBox(
      width: isForgetPasswordScreen ? 200 : null,
      child: ElevatedButton.icon(
        label: Text(AppLocalizations.of(context)!.signIn),
        icon: Icon(Icons.arrow_back),
        onPressed: setAsSignInScreen,
      ),
    );

    var forgetPasswordButton = SizedBox(
      width: 200,
      child: ElevatedButton.icon(
        icon: Icon(Icons.lock_reset),
        label: Text(AppLocalizations.of(context)!.resetPassword),
        onPressed: forgetPassword,
      ),
    );

    var registerUserButton = ElevatedButton.icon(
      label: Text(AppLocalizations.of(context)!.signUp),
      icon: Icon(Icons.person_add),
      onPressed: registerUser,
    );

    List<Widget> buttons = [
      signInButton,
      signUpButton,
      googleSignInButton,
    ];

    if (isForgetPasswordScreen) {
      textFields = [
        emailTextField,
      ];
      buttons = [forgetPasswordButton, backToSignInButton];
    }

    if (isRegistrationScreen) {
      var confirmPasswordTextField = TextFormField(
        keyboardType: TextInputType.visiblePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return AppLocalizations.of(context)!.confirmPasswordRequired;
          }
          return null;
        },
        onChanged: (value) {
          setState(() {
            isPasswordsMatch = passwordsMatch(passwordEditingController.text,
                confirmPasswordEditingController.text);
          });
        },
        focusNode: _confirmPasswordFocusNode,
        controller: confirmPasswordEditingController,
        obscureText: !_isPasswordVisible,
        autofillHints: [AutofillHints.newPassword],
        cursorColor: Colors.purple,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.confirmPassword,
          filled: true,
          isDense: true,
          prefixIcon: Icon(Icons.lock),
          contentPadding: EdgeInsets.fromLTRB(10, 0, 0, 0),
          border: OutlineInputBorder(
              borderRadius: TileStyles.inputFieldBorderRadius,
              borderSide: BorderSide.none),
          fillColor: inputFieldFillColor,
        ),
      );

      textFields = [
        emailTextField,
        spacer(10),
        passwordTextField,
        spacer(10),

        // Conditional rendering for the password validation rules
        if (isPassWordFieldFocused) ...[
          passwordValidatorRules,
          spacer(10),
        ],

        confirmPasswordTextField,
        spacer(10),

        if (isConfirmPassWordFieldFocused) ...[
          confirmPasswordValidatorRules,
          spacer(10),
        ],

        usernameTextField,
        spacer(10),
      ];
      buttons = [registerUserButton, backToSignInButton];
    }

    if (this.isPendingSigning || this.isSuccessfulSignin) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(AppLocalizations.of(context)!.signingIn),
        Spacer(),
      ];
    }
    if (this.isPendingRegistration) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(
            AppLocalizations.of(context)!.registeringUser),
        Spacer(),
      ];
    }
    if (this.isPendingResetPassword) {
      buttons = [
        Spacer(),
        createSignInPendingComponent(AppLocalizations.of(context)!.reset),
        Spacer(),
      ];
    }
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topCenter,
          height: credentialManagerHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0)),
            color: Color.fromRGBO(245, 245, 245, 0.2),
            boxShadow: [
              BoxShadow(
                  color: Color.fromRGBO(245, 245, 245, 0.25), spreadRadius: 5),
            ],
          ),
          padding: EdgeInsets.symmetric(
              vertical: isRegistrationScreen ? calculateSizeByHeight(10) : 0.0,
              horizontal: calculateSizeByHeight(10)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  // height: isRegistrationScreen
                  //     ? height / (height / 200)
                  //     : credentialButtonHeight,
                  padding: EdgeInsets.symmetric(
                      vertical: calculateSizeByHeight(5),
                      horizontal: calculateSizeByHeight(20)),
                  child: AutofillGroup(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: isRegistrationScreen
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.spaceAround,
                      children: textFields,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(0, 5, 0, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: !shouldHideButtons
                        ? buttons
                        : [
                            SizedBox(
                              width: width,
                              height: calculateSizeByHeight(120),
                            )
                          ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
