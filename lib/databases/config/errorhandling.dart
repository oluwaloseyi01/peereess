import 'dart:io';
import 'package:appwrite/appwrite.dart';

class AppError {
  final String message;
  AppError(this.message);

  static AppError from(dynamic error) {
    if (error is SocketException) {
      return AppError('No internet connection. Please check your network.');
    }

    if (error is AppwriteException) {
      switch (error.code) {
        case 401:
          return AppError('Invalid email or password.');
        case 400:
          return AppError('Please check your details and try again.');
        case 403:
          return AppError("You don't have permission to do this.");
        case 404:
          return AppError('Account not found.');
        case 409:
          return AppError('An account with this email already exists.');
        case 429:
          return AppError('Too many attempts. Please try again later.');
        case 500:
        case 502:
        case 503:
          return AppError('Server error. Please try again later.');
        default:
          return AppError('Something went wrong. Please try again.');
      }
    }

    if (error is Exception) {
      final msg = error.toString().replaceFirst('Exception: ', '');
      if (msg.isNotEmpty) return AppError(msg);
    }

    return AppError('Something went wrong. Please try again.');
  }
}
