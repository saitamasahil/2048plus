.class public Lorg/libsdl/app/VibrationHelper;
.super Ljava/lang/Object;
.source "VibrationHelper.java"

.method public constructor <init>()V
    .locals 0

    invoke-direct {p0}, Ljava/lang/Object;-><init>()V

    return-void
.end method

.method public static vibrate(D)V
    .locals 6

    # Ignore non positive duration
    const-wide/16 v0, 0x0

    cmpl-double v2, p0, v0

    if-gtz v2, :cond_exit

    return-void

    :cond_exit
    :try_start_0
    # Convert seconds to milliseconds
    const-wide v0, 0x408f400000000000L    # 1000.0

    mul-double/2addr p0, v0

    double-to-long v0, p0

    # Minimum duration for hardware motors
    const-wide/16 v2, 0x1e    # 30 ms

    cmp-long v4, v0, v2

    if-gez v4, :cond_have_ms

    move-wide v0, v2

    :cond_have_ms
    # Obtain Context instance
    sget-object v2, Lorg/libsdl/app/SDLActivity;->mSingleton:Lorg/libsdl/app/SDLActivity;

    if-nez v2, :cond_have_context

    return-void

    :cond_have_context
    const/4 v3, 0x0

    # Check VibratorManager on modern Android
    sget v4, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v5, 0x1f    # API 31

    if-lt v4, v5, :cond_check_vibrator

    const-string v4, "vibrator_manager"

    invoke-virtual {v2, v4}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v4

    check-cast v4, Landroid/os/VibratorManager;

    if-eqz v4, :cond_check_vibrator

    invoke-virtual {v4}, Landroid/os/VibratorManager;->getDefaultVibrator()Landroid/os/Vibrator;

    move-result-object v3

    :cond_check_vibrator
    # Check legacy Vibrator
    if-nez v3, :cond_check_has_vibrator

    const-string v4, "vibrator"

    invoke-virtual {v2, v4}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v2

    move-object v3, v2

    check-cast v3, Landroid/os/Vibrator;

    :cond_check_has_vibrator
    if-nez v3, :cond_check_has_vib

    return-void

    :cond_check_has_vib
    # Ensure device has vibrator hardware
    invoke-virtual {v3}, Landroid/os/Vibrator;->hasVibrator()Z

    move-result v2

    if-nez v2, :cond_do_vibrate

    return-void

    :cond_do_vibrate
    sget v2, Landroid/os/Build$VERSION;->SDK_INT:I

    const/16 v4, 0x1a    # API 26

    if-lt v2, v4, :cond_legacy_vibrate

    # Modern VibrationEffect with game audio attributes
    const/4 v2, -0x1

    invoke-static {v0, v1, v2}, Landroid/os/VibrationEffect;->createOneShot(JI)Landroid/os/VibrationEffect;

    move-result-object v2

    new-instance v4, Landroid/media/AudioAttributes$Builder;

    invoke-direct {v4}, Landroid/media/AudioAttributes$Builder;-><init>()V

    const/16 v5, 0xe    # AudioAttributes USAGE_GAME

    invoke-virtual {v4, v5}, Landroid/media/AudioAttributes$Builder;->setUsage(I)Landroid/media/AudioAttributes$Builder;

    move-result-object v4

    const/4 v5, 0x4    # AudioAttributes CONTENT_TYPE_SONIFICATION

    invoke-virtual {v4, v5}, Landroid/media/AudioAttributes$Builder;->setContentType(I)Landroid/media/AudioAttributes$Builder;

    move-result-object v4

    invoke-virtual {v4}, Landroid/media/AudioAttributes$Builder;->build()Landroid/media/AudioAttributes;

    move-result-object v4

    invoke-virtual {v3, v2, v4}, Landroid/os/Vibrator;->vibrate(Landroid/os/VibrationEffect;Landroid/media/AudioAttributes;)V

    goto :goto_end

    :cond_legacy_vibrate
    # Legacy vibrator fallback
    invoke-virtual {v3, v0, v1}, Landroid/os/Vibrator;->vibrate(J)V
    :try_end_0
    .catchall {:try_start_0 .. :try_end_0} :catch_all

    goto :goto_end

    :catch_all
    # Safety exception handler
    :try_start_1
    sget-object v2, Lorg/libsdl/app/SDLActivity;->mSingleton:Lorg/libsdl/app/SDLActivity;

    if-eqz v2, :cond_goto_end

    const-string v3, "vibrator"

    invoke-virtual {v2, v3}, Landroid/content/Context;->getSystemService(Ljava/lang/String;)Ljava/lang/Object;

    move-result-object v2

    check-cast v2, Landroid/os/Vibrator;

    if-eqz v2, :cond_goto_end

    invoke-virtual {v2, v0, v1}, Landroid/os/Vibrator;->vibrate(J)V
    :try_end_1
    .catchall {:try_start_1 .. :try_end_1} :catch_ignore

    :cond_goto_end
    :goto_end
    return-void

    :catch_ignore
    return-void
.end method
