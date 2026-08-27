// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get catalogDashboard => 'Catálogo / Tablero';

  @override
  String get profile => 'PERFIL';

  @override
  String get overallProgress => 'Progreso general';

  @override
  String get overallPerformance => 'Rendimiento general';

  @override
  String get topics => 'TEMAS';

  @override
  String get workspace => 'ESPACIO DE TRABAJO';

  @override
  String get language => 'IDIOMA';

  @override
  String get logout => 'CERRAR SESIÓN';

  @override
  String get poweredBy => 'Desarrollado por eMe.world';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get newTutorials => '3 Nuevas';

  @override
  String get level => 'Nivel 10';

  @override
  String get avgSuffix => 'Promedio';

  @override
  String get newTutorialTitle => 'Nuevo Tutorial Disponible';

  @override
  String get newTutorialBody => 'Competencia Matemática 2 ha sido desbloqueada.';

  @override
  String get achievementTitle => 'Logro Desbloqueado';

  @override
  String get achievementBody => 'Completaste 3 pruebas de diagnóstico del tema.';

  @override
  String get time5m => 'Hace 5m';

  @override
  String get time2h => 'Hace 2h';

  @override
  String tutorialsCount(String count) {
    return '$count tutoriales';
  }

  @override
  String get daysToGo => 'días restantes';

  @override
  String get efficiency => 'eficiencia';

  @override
  String get moderate => 'Moderado';

  @override
  String lastUpdated(String date) {
    return 'Última actualización: $date';
  }

  @override
  String get tutorials => 'Tutoriales';

  @override
  String get totalTutorials => 'TUTORIALES TOTALES';

  @override
  String activeTutorials(String count) {
    return '$count Tutoriales Activos';
  }

  @override
  String get testsPerformance => 'RENDIMIENTO DE PRUEBAS';

  @override
  String averageScore(String progress) {
    return '$progress% Puntaje Promedio';
  }

  @override
  String get overallTopicProgress => 'Progreso General del Tema';

  @override
  String finished(String percent) {
    return '$percent% Finalizado';
  }

  @override
  String get beginner => 'Principiante';

  @override
  String get competent => 'Aprendiz';

  @override
  String get expert => 'Experto';

  @override
  String get topicsYouExcelAt => 'Temas en los que sobresales';

  @override
  String get averageRank => 'Rango Promedio';

  @override
  String get nextRankUp => 'Siguiente Nivel En';

  @override
  String get improve => 'Mejorar';

  @override
  String get refresh => 'Refrescar';

  @override
  String lastReviewed(String d) {
    return 'Última revisión $d días atrás';
  }

  @override
  String get confidence => 'Confianza';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get appCompliance => 'Privacidad y datos';

  @override
  String get dataConsentTitle => 'Divulgación y Consentimiento de Datos';

  @override
  String get dataConsentBody => 'Valoramos su privacidad. Recopilamos datos de la cuenta (correo, nombre), interacciones de chat y progreso de aprendizaje para ofrecer tutoría con IA personalizada. Todos los datos se transmiten de forma segura por HTTPS y se guardan con seguridad. No vendemos sus datos personales.';

  @override
  String get acceptConsent => 'Continuar';

  @override
  String get declineConsent => 'Rechazar';

  @override
  String get deleteAccount => 'Eliminar Cuenta';

  @override
  String get deleteAccountConfirm => '¿Está seguro de que desea eliminar su cuenta? Esta acción es permanente y borrará sus credenciales, historial y datos de perfil.';

  @override
  String get deleteData => 'Eliminar Datos Recopilados';

  @override
  String get deleteDataConfirm => '¿Está seguro de que desea eliminar todos los datos de aprendizaje y chat recopilados? Esto no se puede deshacer.';

  @override
  String get aiGenerated => 'Generado por IA';

  @override
  String get reportAi => 'Reportar Respuesta de IA';

  @override
  String get reportAiSuccess => '¡Gracias! Su reporte ha sido enviado para revisión.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get reasonHallucination => 'Alucinación / Información Inexacta';

  @override
  String get reasonInappropriate => 'Contenido Inapropiado';

  @override
  String get reasonOffensive => 'Lenguaje Ofensivo';

  @override
  String get reasonOther => 'Otro Problema';

  @override
  String get accountManagementTitle => 'Gestión de Cuenta y Datos';

  @override
  String get accountManagementBody => 'Tienes control total sobre tus datos. Puedes borrar tus datos recopilados o eliminar permanentemente tu cuenta en cualquier momento.';

  @override
  String get verificationCodeSent => '¡Código de verificación enviado a tu correo electrónico!';

  @override
  String get verificationCodeResent => '¡Código de verificación reenviado a tu correo electrónico!';

  @override
  String get userDoesNotExist => 'El usuario no existe.';

  @override
  String get failedToSendCode => 'Error al enviar el código';

  @override
  String get pleaseEnterAll6Digits => 'Por favor, ingresa los 6 dígitos';

  @override
  String get invalidVerificationCode => 'Código de verificación inválido. Por favor, inténtalo de nuevo.';

  @override
  String get createAccount => 'Crear Cuenta';

  @override
  String get editEmail => 'Editar Correo';

  @override
  String noAccountFoundRegister(String email) {
    return 'No se encontró ninguna cuenta para $email. Por favor, ingresa tus datos para registrarte.';
  }

  @override
  String get firstName => 'Nombre';

  @override
  String get enterFirstName => 'Ingresa tu nombre';

  @override
  String get pleaseEnterFirstName => 'Por favor, ingresa tu nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get enterLastName => 'Ingresa tu apellido';

  @override
  String get pleaseEnterLastName => 'Por favor, ingresa tu apellido';

  @override
  String get emailAddress => 'Correo Electrónico';

  @override
  String get enterEmail => 'Ingresa tu correo';

  @override
  String get pleaseEnterEmail => 'Por favor, ingresa tu correo electrónico';

  @override
  String get pleaseEnterValidEmail => 'Por favor, ingresa un correo electrónico válido';

  @override
  String get verificationCode => 'Código de Verificación';

  @override
  String sentToEmail(String email) {
    return 'Enviado a $email';
  }

  @override
  String workspacePrefix(String name) {
    return 'Espacio de trabajo: $name';
  }

  @override
  String resendCodeIn(String seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get didntReceiveCode => '¿No recibiste el código? ';

  @override
  String get resendCode => 'Reenviar Código';

  @override
  String get registerAndSendCode => 'Registrar y Enviar Código';

  @override
  String get verifyAndSignIn => 'Verificar e Iniciar Sesión';

  @override
  String get sendVerificationCode => 'Enviar Código de Verificación';

  @override
  String get selectWorkspace => 'Seleccionar Espacio de Trabajo';

  @override
  String get workspaceRemoved => 'Espacio de trabajo eliminado';

  @override
  String get failedToRemoveWorkspace => 'Error al eliminar espacio de trabajo';

  @override
  String get deleteWorkspace => 'Eliminar Espacio de Trabajo';

  @override
  String deleteWorkspaceConfirm(String name, String root) {
    return '¿Estás seguro de que deseas eliminar el espacio de trabajo \"$name\" ($root)?';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get consentUpdatedAccepted => 'Consentimiento de recopilación de datos actualizado a Aceptado.';

  @override
  String get consentUpdatedEssential => 'Consentimiento de recopilación de datos actualizado a Solo esenciales.';

  @override
  String get failedToUpdateConsent => 'Error al actualizar la preferencia de consentimiento';

  @override
  String get dataDeletionRequested => 'Se ha solicitado la eliminación de los datos personales recopilados.';

  @override
  String get failedToRequestDataDeletion => 'Error al solicitar la eliminación de datos';

  @override
  String get dataCollectionConsentStatus => 'Estado de consentimiento de recopilación de datos';

  @override
  String get accountInfoTitle => 'Información de la Cuenta';

  @override
  String get accountInfoSubtitle => 'Nombre, dirección de correo electrónico y credenciales de autenticación.';

  @override
  String get interactiveChatLearningTitle => 'Datos de Chat Interactivo y Aprendizaje';

  @override
  String get interactiveChatLearningSubtitle => 'Preguntas, respuestas, puntuaciones de pruebas diagnósticas y progreso.';

  @override
  String get dataProtectionTitle => 'Protección y Encriptación de Datos';

  @override
  String get dataProtectionSubtitle => 'Transmisión HTTPS y almacenamiento seguro en la nube.';

  @override
  String failedToLoadTopics(String error) {
    return 'Error al cargar los temas: $error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get noTopicsAvailable => 'No hay temas disponibles.';

  @override
  String get viewProfile => 'Ver perfil';

  @override
  String get catalog => 'Catálogo';

  @override
  String couldNotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String failedToLoadTutorials(String error) {
    return 'Error al cargar los tutoriales: $error';
  }

  @override
  String get noTutorialsAvailable => 'No hay tutoriales disponibles.';

  @override
  String get failedToSelectImage => 'Error al seleccionar imagen';

  @override
  String get profileUpdatedSuccessfully => 'Perfil actualizado exitosamente';

  @override
  String get failedToUpdateProfile => 'Error al actualizar perfil';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get email => 'Correo Electrónico';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String fieldIsRequired(String label) {
    return '$label es obligatorio';
  }

  @override
  String get accountDataCleared => 'Datos de la cuenta borrados exitosamente.';

  @override
  String get failedToClearAccountData => 'Error al borrar los datos de la cuenta';

  @override
  String plusMoreCount(String count) {
    return '+$count más';
  }

  @override
  String get intermediate => 'Intermedio';

  @override
  String get failedToLoadTutorialSession => 'Error al cargar la sesión del tutorial';

  @override
  String get failedToSubmitAnswer => 'Error al enviar la respuesta';

  @override
  String get failedToSendFollowUp => 'Error al enviar seguimiento';

  @override
  String get failedToContinueTutorial => 'Error al continuar el tutorial';

  @override
  String get reportDetailsPrompt => 'Reportar alucinación, información inexacta o respuesta inapropiada de la IA:';

  @override
  String get additionalDetailsOptional => 'Detalles adicionales (opcional)...';

  @override
  String get report => 'Reportar';

  @override
  String get correct => '¡Correcto!';

  @override
  String get incorrect => 'Incorrecto.';

  @override
  String get errorLoadingChat => 'Ocurrió un error al cargar el chat.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get start => 'Iniciar';

  @override
  String get askFollowUpHint => 'Haz una pregunta de seguimiento...';

  @override
  String get send => 'Enviar';

  @override
  String get continueButton => 'Continuar';

  @override
  String get howConfidentQuestion => '¿QUÉ TAN SEGURO ESTÁS DE ESTA RESPUESTA?';

  @override
  String get submitAnswer => 'Enviar Respuesta';

  @override
  String get connectingToTutorSession => 'Conectando a la sesión de tutoría...';

  @override
  String get quizCompleted => '¡Cuestionario Completado! 🎉';

  @override
  String get goBack => '¡Volver!';

  @override
  String get failedToLoadImage => 'Error al cargar la imagen';

  @override
  String get openInBrowser => 'Abrir en el navegador';

  @override
  String get failedToPlayVideo => 'Error al reproducir el video';

  @override
  String get openVideoExternally => 'Abrir video externamente';

  @override
  String get failedToLoadAudio => 'Error al cargar el audio';

  @override
  String get openAudioLink => 'Abrir enlace de audio';

  @override
  String get loadingDocument => 'Cargando documento...';

  @override
  String get failedToDisplayPdf => 'Error al mostrar el documento PDF';

  @override
  String get openPdfInBrowser => 'Abrir PDF en el navegador';

  @override
  String pageOfTotal(String current, String total) {
    return 'Página $current de $total';
  }

  @override
  String get pictureInPicture => 'Imagen en imagen';

  @override
  String get openLink => 'Abrir enlace';

  @override
  String get mediaViewer => 'Visor de medios';

  @override
  String get couldNotLaunchMediaUrl => 'No se pudo abrir la URL del medio';

  @override
  String get mediaPreview => 'Vista previa de medios';

  @override
  String get videoPreview => 'Vista previa de video';

  @override
  String get failedToLoadVideo => 'Error al cargar el video';

  @override
  String get openExternal => 'Abrir externo';

  @override
  String get fullScreen => 'Pantalla completa';

  @override
  String get pipVideo => 'Video PiP';

  @override
  String answersForgottenSummary(String percent, String days) {
    return 'Un promedio de $percent% de respuestas olvidadas en $days días';
  }
}
