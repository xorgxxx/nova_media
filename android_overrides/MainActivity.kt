package com.novamedia.nova_media

import com.ryanheise.audioservice.AudioServiceActivity

// Required by just_audio_background / audio_service so the notification and
// lock-screen controls can attach to the Flutter activity.
class MainActivity : AudioServiceActivity()
