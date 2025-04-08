import 'package:shared_preferences/shared_preferences.dart';

class AvatarSettings {
  // Available avatars
  static const List<Map<String, String>> availableAvatars = [
    {
      'name': 'SpongeBob',
      'imagePath': 'assets/spongebob.png',
      'voicePath': 'sounds/SpongBob.wav'
    },
    {
      'name': 'Patrick',
      'imagePath': 'assets/patrick.png',
      'voicePath': 'sounds/Patrick.wav'
    },
    {
      'name': 'Squidward',
      'imagePath': 'assets/squidward.png',
      'voicePath': 'sounds/Squidward.wav'
    },
    {
      'name': 'Mr. Krabs',
      'imagePath': 'assets/mr_krabs.png',
      'voicePath': 'sounds/MrKrabs.wav'
    },
    {
      'name': 'Sandy',
      'imagePath': 'assets/sandy.png',
      'voicePath': 'sounds/Sandy.wav'
    },
  ];

  // Key constants for SharedPreferences
  static const String _avatarNameKey = 'avatar_name';
  static const String _avatarImagePathKey = 'avatar_image_path';
  static const String _avatarVoicePathKey = 'avatar_voice_path';

  // Default avatar
  static const String defaultAvatarName = 'SpongeBob';
  static const String defaultImagePath = 'assets/spongebob.png';
  static const String defaultVoicePath = 'sounds/SpongBob.wav';

  // Get current avatar settings
  static Future<Map<String, String>> getCurrentAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'name': prefs.getString(_avatarNameKey) ?? defaultAvatarName,
      'imagePath': prefs.getString(_avatarImagePathKey) ?? defaultImagePath,
      'voicePath': prefs.getString(_avatarVoicePathKey) ?? defaultVoicePath,
    };
  }

  // Save avatar settings
  static Future<void> saveAvatar(String name, String imagePath, String voicePath) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString(_avatarNameKey, name);
    await prefs.setString(_avatarImagePathKey, imagePath);
    await prefs.setString(_avatarVoicePathKey, voicePath);
  }

  // Reset to default avatar
  static Future<void> resetToDefault() async {
    await saveAvatar(defaultAvatarName, defaultImagePath, defaultVoicePath);
  }

  // Find avatar by name
  static Map<String, String>? findAvatarByName(String name) {
    try {
      return availableAvatars.firstWhere((avatar) => avatar['name'] == name);
    } catch (e) {
      return null;
    }
  }
}