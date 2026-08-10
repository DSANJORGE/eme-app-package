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
}
