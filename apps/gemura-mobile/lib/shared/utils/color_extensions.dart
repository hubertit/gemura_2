import 'dart:ui';

extension ColorChannels on Color {
  int get r => (value >> 16) & 0xFF;
  int get g => (value >> 8) & 0xFF;
  int get b => value & 0xFF;
  int get a => (value >> 24) & 0xFF; // Return int 0–255
} 