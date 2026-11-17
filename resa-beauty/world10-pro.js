/* DIGIY BEAUTY PRO · WORLD10 presentation only. No modification to booking RPC, owner access or personal data. */
(()=>{
 "use strict";
 const langs=["fr","en","es","pt","de","it","nl","ar","wo","zh"];
 const names=["🇫🇷 FR","🇬🇧 EN","🇪🇸 ES","🇵🇹 PT","🇩🇪 DE","🇮🇹 IT","🇳🇱 NL","🇸🇦 AR","🇸🇳 WO","🇨🇳 ZH"];
 const rows=[["Accès propriétaire BEAUTY","BEAUTY owner access","Acceso propietario BEAUTY","Acesso proprietário BEAUTY","BEAUTY Inhaberzugang","Accesso proprietario BEAUTY","BEAUTY eigenaarstoegang","دخول مالك BEAUTY","Duggub boroom BEAUTY","BEAUTY 业主入口"],["Gestion BEAUTY — DIGIYLYFE","BEAUTY management — DIGIYLYFE","Gestión BEAUTY — DIGIYLYFE","Gestão BEAUTY — DIGIYLYFE","BEAUTY Verwaltung — DIGIYLYFE","Gestione BEAUTY — DIGIYLYFE","BEAUTY beheer — DIGIYLYFE","إدارة BEAUTY — DIGIYLYFE","Saytu BEAUTY — DIGIYLYFE","BEAUTY 管理 — DIGIYLYFE"],["💇 Accès propriétaire","💇 Owner access","💇 Acceso propietario","💇 Acesso proprietário","💇 Inhaberzugang","💇 Accesso proprietario","💇 Eigenaarstoegang","💇 دخول المالك","💇 Duggub boroom","💇 业主入口"],["Email propriétaire","Owner email","Correo del propietario","Email do proprietário","Inhaber-E-Mail","Email del proprietario","E-mail eigenaar","بريد المالك","Imeelu boroom","业主邮箱"],["RECEVOIR MON ACCÈS","SEND ME MY ACCESS","RECIBIR MI ACCESO","RECEBER O MEU ACESSO","ZUGANG ANFORDERN","RICEVI IL MIO ACCESSO","TOEGANG ONTVANGEN","إرسال رابط الدخول","JOT SAMA DUGG","获取登录链接"],["Email requis","Email required","Correo obligatorio","Email obrigatório","E-Mail erforderlich","Email obbligatoria","E-mail verplicht","البريد الإلكتروني مطلوب","Imeel war na am","请输入邮箱"],["Email envoyé.","Email sent.","Correo enviado.","Email enviado.","E-Mail gesendet.","Email inviata.","E-mail verzonden.","تم إرسال البريد.","Yónnee nañu imeel bi.","邮件已发送。"],["⚠️ Restaurant BEAUTY non identifié. Ouvre ton accès depuis ta fiche professionnelle.","⚠️ BEAUTY business not identified. Open owner access from your professional profile.","⚠️ Negocio BEAUTY no identificado. Entra desde tu ficha profesional.","⚠️ Estabelecimento BEAUTY não identificado. Entre pela sua ficha profissional.","⚠️ BEAUTY-Betrieb nicht gefunden. Öffnen Sie den Zugang über Ihr Profil.","⚠️ Attività BEAUTY non identificata. Accedi dalla scheda professionale.","⚠️ BEAUTY-zaak niet gevonden. Open de toegang via je profiel.","⚠️ لم يتم تحديد نشاط BEAUTY. افتح دخول المالك من صفحتك المهنية.","⚠️ Xameesu liggéey BEAUTY bi. Ubbi duggub boroom ci sa fich.","⚠️ 未找到 BEAUTY 商家。请从商家主页进入业主入口。"],["⚠️ Restaurant BEAUTY non identifié. Retourne à la fiche professionnelle.","⚠️ BEAUTY business not identified. Return to the professional profile.","⚠️ Negocio BEAUTY no identificado. Vuelve a la ficha profesional.","⚠️ Estabelecimento BEAUTY não identificado. Volte à ficha profissional.","⚠️ BEAUTY-Betrieb nicht gefunden. Zurück zum Profil.","⚠️ Attività BEAUTY non identificata. Torna alla scheda professionale.","⚠️ BEAUTY-zaak niet gevonden. Ga terug naar je profiel.","⚠️ لم يتم تحديد نشاط BEAUTY. عد إلى الصفحة المهنية.","⚠️ Xameesu liggéey BEAUTY bi. Dellul ci sa fich.","⚠️ 未找到 BEAUTY 商家。请返回商家主页。"],["← Vue publique","← Public view","← Vista pública","← Vista pública","← Öffentliche Ansicht","← Vista pubblica","← Openbare weergave","العرض العام →","← Xoolu ñépp","← 公开页面"],["Connexion…","Connecting…","Conectando…","A ligar…","Verbindung läuft…","Connessione…","Verbinden…","جارٍ الاتصال…","Dugg bi di dox…","连接中…"],["Déconnexion","Sign out","Cerrar sesión","Terminar sessão","Abmelden","Esci","Afmelden","تسجيل الخروج","Génn","退出登录"],["Présence & contact","Presence & contact","Presencia y contacto","Presença e contacto","Präsenz & Kontakt","Presenza e contatto","Zichtbaarheid en contact","الظهور والتواصل","Feeñ ak jokkoo","展示与联系"],["Disponibilité","Availability","Disponibilidad","Disponibilidade","Verfügbarkeit","Disponibilità","Beschikbaarheid","التوفر","Li féex","营业状态"],["Disponible","Available","Disponible","Disponível","Verfügbar","Disponibile","Beschikbaar","متاح","Am na","可用"],["Occupé","Busy","Ocupado","Ocupado","Beschäftigt","Occupato","Bezet","مشغول","Japp na","忙碌"],["Indisponible","Unavailable","No disponible","Indisponível","Nicht verfügbar","Non disponibile","Niet beschikbaar","غير متاح","Amul","不可用"],["WhatsApp public","Public WhatsApp","WhatsApp público","WhatsApp público","Öffentliches WhatsApp","WhatsApp pubblico","Openbare WhatsApp","واتساب العام","WhatsApp bu ñépp gis","公开 WhatsApp"],["Ville","City","Ciudad","Cidade","Stadt","Città","Stad","المدينة","Dëkk","城市"],["Zone / territoire","Area / location","Zona / territorio","Zona / território","Bereich / Region","Zona / territorio","Gebied / regio","المنطقة / الإقليم","Béréb / territoire","区域 / 地区"],["Note d’ouverture","Opening note","Nota de apertura","Nota de abertura","Hinweis zur Öffnung","Nota di apertura","Openingsbericht","ملاحظة عن المواعيد","Nettali waxtu ubbi","营业说明"],["Ex : Créneaux test · confirmation directe par le salon","E.g. Test slots · confirmation directly by the salon","Ej. Horarios de prueba · confirmación directa por el salón","Ex. Horários teste · confirmação direta pelo salão","Z. B. Testtermine · Bestätigung durch den Salon","Es. Orari di prova · conferma diretta del salone","Bijv. Testtijden · directe bevestiging door de salon","مثال: مواعيد تجريبية · تأكيد مباشر من الصالون","Misaal: waxtu test · salon bi mooy dëggal","例如：测试时段 · 由沙龙直接确认"],["Prestations & tarifs","Services & prices","Servicios y tarifas","Serviços e preços","Leistungen & Preise","Prestazioni e prezzi","Diensten en prijzen","الخدمات والأسعار","Sarwiis ak njëg","服务与价格"],["Le propriétaire peut ajouter, modifier ou retirer ses prestations.","The owner can add, edit or remove services.","El propietario puede añadir, editar o quitar servicios.","O proprietário pode adicionar, alterar ou remover serviços.","Der Inhaber kann Leistungen hinzufügen, ändern oder entfernen.","Il proprietario può aggiungere, modificare o eliminare servizi.","De eigenaar kan diensten toevoegen, wijzigen of verwijderen.","يمكن للمالك إضافة الخدمات أو تعديلها أو حذفها.","Boroom bi mën na yokk, soppi walla far sarwiis yi.","业主可以添加、修改或删除服务。"],["+ Ajouter une prestation","+ Add a service","+ Añadir un servicio","+ Adicionar serviço","+ Leistung hinzufügen","+ Aggiungi servizio","+ Dienst toevoegen","إضافة خدمة +","+ Yokkal sarwiis","+ 添加服务"],["Prestation","Service","Servicio","Serviço","Leistung","Prestazione","Dienst","الخدمة","Sarwiis","服务"],["Durée (min)","Duration (min)","Duración (min)","Duração (min)","Dauer (Min.)","Durata (min)","Duur (min)","المدة (دقيقة)","Diir (simili)","时长（分钟）"],["Tarif FCFA","Price FCFA","Precio FCFA","Preço FCFA","Preis FCFA","Prezzo FCFA","Prijs FCFA","السعر فرنك غرب أفريقيا","Njëg FCFA","价格（FCFA）"],["Demandes de réservation","Booking requests","Solicitudes de reserva","Pedidos de reserva","Buchungsanfragen","Richieste di prenotazione","Reserveringsaanvragen","طلبات الحجز","Laaju rezervaasiyoŋ","预约申请"],["Le client prépare sa demande. Tu confirmes ou refuses directement.","The customer sends a request. You confirm or decline it directly.","El cliente envía una solicitud. Tú la confirmas o rechazas.","O cliente envia um pedido. Confirma ou recusa diretamente.","Der Kunde stellt eine Anfrage. Sie bestätigen oder lehnen direkt ab.","Il cliente invia una richiesta. Confermi o rifiuti direttamente.","De klant doet een aanvraag. Je bevestigt of weigert direct.","يرسل العميل طلبًا. يمكنك تأكيده أو رفضه مباشرة.","Kiliyaan bi dafay laaj. Yow yaa koy dëggal walla bañ.","客户提交预约请求，由您直接确认或拒绝。"],["📅 Mon planning sur sept jours","📅 My seven-day calendar","📅 Mi agenda de siete días","📅 A minha agenda de sete dias","📅 Mein Sieben-Tage-Plan","📅 La mia agenda di sette giorni","📅 Mijn zevendaagse planning","📅 جدولي لسبعة أيام","📅 Sama planningu 7 bés","📅 我的七日排期"],["Ouvre uniquement les jours et heures que tu choisis. Les réservations et les créneaux déjà bloqués ne seront pas modifiés. L'ouverture de la semaine demande une connexion propriétaire.","Open only the days and times you choose. Existing bookings and blocked slots are untouched. Opening the week requires owner login.","Abre solo los días y horas que elijas. Las reservas y horarios bloqueados no cambian. Se requiere acceso de propietario.","Abra só os dias e horas que escolher. Reservas e horários bloqueados mantêm-se. É necessário acesso do proprietário.","Öffnen Sie nur die gewünschten Tage und Zeiten. Buchungen und Sperren bleiben erhalten. Inhaberzugang erforderlich.","Apri solo i giorni e gli orari scelti. Prenotazioni e blocchi restano invariati. Serve l'accesso proprietario.","Open alleen gekozen dagen en tijden. Boekingen en blokkades blijven behouden. Eigenaarstoegang vereist.","افتح الأيام والأوقات التي تختارها فقط. لا تتغير الحجوزات والمواعيد المحجوبة. يلزم دخول المالك.","Ubbi bés ak waxtu yi nga tànn rekk. Rezervaasiyoŋ ak waxtu yu ñu téye duñu soppi. Duggub boroom war na.","仅开放您选择的日期和时间。现有预约和已锁定时段不受影响。需业主登录。"],["Semaine commençant le lundi","Week starting Monday","Semana que empieza el lunes","Semana a partir de segunda-feira","Woche ab Montag","Settimana a partire da lunedì","Week vanaf maandag","الأسبوع الذي يبدأ الاثنين","Ayu-bés bu tàmbalee Altine","从周一开始的一周"],["Jours où tu reçois","Days you receive clients","Días de atención","Dias de atendimento","Tage mit Terminen","Giorni di ricevimento","Dagen met afspraken","أيام استقبال العملاء","Bés yi nga nangu kiliyaan","接待客户的日期"],["Lundi","Monday","Lunes","Segunda","Montag","Lunedì","Maandag","الاثنين","Altine","周一"],["Mardi","Tuesday","Martes","Terça","Dienstag","Martedì","Dinsdag","الثلاثاء","Talaata","周二"],["Mercredi","Wednesday","Miércoles","Quarta","Mittwoch","Mercoledì","Woensdag","الأربعاء","Àllarba","周三"],["Jeudi","Thursday","Jueves","Quinta","Donnerstag","Giovedì","Donderdag","الخميس","Alxames","周四"],["Vendredi","Friday","Viernes","Sexta","Freitag","Venerdì","Vrijdag","الجمعة","Àjjuma","周五"],["Samedi","Saturday","Sábado","Sábado","Samstag","Sabato","Zaterdag","السبت","Gaawu","周六"],["Dimanche","Sunday","Domingo","Domingo","Sonntag","Domenica","Zondag","الأحد","Dibéer","周日"],["Heure 1","Time 1","Hora 1","Hora 1","Zeit 1","Ora 1","Tijd 1","الوقت 1","Waxtu 1","时间 1"],["Heure 2","Time 2","Hora 2","Hora 2","Zeit 2","Ora 2","Tijd 2","الوقت 2","Waxtu 2","时间 2"],["Heure 3","Time 3","Hora 3","Hora 3","Zeit 3","Ora 3","Tijd 3","الوقت 3","Waxtu 3","时间 3"],["Heure 4","Time 4","Hora 4","Hora 4","Zeit 4","Ora 4","Tijd 4","الوقت 4","Waxtu 4","时间 4"],["Heure 5","Time 5","Hora 5","Hora 5","Zeit 5","Ora 5","Tijd 5","الوقت 5","Waxtu 5","时间 5"],["Heure 6","Time 6","Hora 6","Hora 6","Zeit 6","Ora 6","Tijd 6","الوقت 6","Waxtu 6","时间 6"],["Le professionnel choisit librement les jours et les heures qu’il souhaite proposer. Aucune heure ni journée n’est imposée : seuls les créneaux volontairement ouverts deviennent visibles.","The professional chooses which days and times to offer. No hours or days are imposed: only intentionally opened slots become visible.","El profesional elige libremente sus días y horarios. Nada se impone: solo aparecen los horarios abiertos voluntariamente.","O profissional escolhe livremente dias e horários. Nada é imposto: só aparecem os horários abertos voluntariamente.","Der Profi entscheidet frei über Tage und Zeiten. Nur ausdrücklich freigegebene Termine werden sichtbar.","Il professionista sceglie liberamente giorni e orari. Sono visibili solo quelli aperti volontariamente.","De professional kiest zelf dagen en tijden. Alleen bewust geopende tijdsloten zijn zichtbaar.","يختار المهني الأيام والأوقات بحرية. لا تُفرض مواعيد؛ تظهر فقط الفترات المفتوحة عمدًا.","Boroom liggéey bi mooy tànn bés ak waxtu yi mu bëgg. Amul waxtu bu ñu ko teg; yi mu ubbi rekk lañuy feeñ.","专业人士自主选择开放日期和时间。系统不强制排期，仅显示主动开放的时段。"],["📅 Ouvrir ces créneaux","📅 Open these slots","📅 Abrir estos horarios","📅 Abrir estes horários","📅 Diese Zeiten freigeben","📅 Apri questi orari","📅 Open deze tijdsloten","📅 فتح هذه المواعيد","📅 Ubbi waxtu yii","📅 开放这些时段"],["Gestion détaillée des créneaux","Detailed slot management","Gestión detallada de horarios","Gestão detalhada de horários","Detaillierte Terminverwaltung","Gestione dettagliata orari","Gedetailleerd tijdslotbeheer","إدارة المواعيد التفصيلية","Saytu waxtu yi ci ndigal","详细时段管理"],["Choisis une date puis ouvre, bloque ou marque un créneau réservé.","Choose a date, then open, block or mark a slot as booked.","Elige una fecha para abrir, bloquear o marcar un horario como reservado.","Escolha uma data para abrir, bloquear ou marcar um horário como reservado.","Wählen Sie einen Tag und öffnen, sperren oder buchen Sie eine Zeit.","Scegli una data e apri, blocca o segna uno slot come prenotato.","Kies een datum en open, blokkeer of markeer een slot als geboekt.","اختر تاريخًا ثم افتح موعدًا أو احجبه أو حدده محجوزًا.","Tànnal bés ba noppi ubbi, tëj walla màndargaal waxtu bu ñu rezervé.","选择日期后开放、锁定或标记时段为已预约。"],["Jour","Day","Día","Dia","Tag","Giorno","Dag","اليوم","Bés","日期"],["Statut","Status","Estado","Estado","Status","Stato","Status","الحالة","Naka la","状态"],["Bloqué","Blocked","Bloqueado","Bloqueado","Gesperrt","Bloccato","Geblokkeerd","محجوب","Tëj na","已锁定"],["Réservé","Booked","Reservado","Reservado","Gebucht","Prenotato","Geboekt","محجوز","Rezervé na","已预约"],["ENREGISTRER LES MODIFICATIONS","SAVE CHANGES","GUARDAR CAMBIOS","GUARDAR ALTERAÇÕES","ÄNDERUNGEN SPEICHERN","SALVA MODIFICHE","WIJZIGINGEN OPSLAAN","حفظ التعديلات","DENC SOPPALI YI","保存修改"],["Nouvelle demande","New request","Nueva solicitud","Novo pedido","Neue Anfrage","Nuova richiesta","Nieuwe aanvraag","طلب جديد","Laaj bu bees","新申请"],["Confirmée","Confirmed","Confirmada","Confirmada","Bestätigt","Confermata","Bevestigd","تم التأكيد","Dëggal nañu","已确认"],["Refusée","Declined","Rechazada","Recusada","Abgelehnt","Rifiutata","Geweigerd","مرفوض","Bañ nañu","已拒绝"],["Client","Customer","Cliente","Cliente","Kunde","Cliente","Klant","العميل","Kiliyaan","客户"],["💬 WhatsApp client","💬 Customer WhatsApp","💬 WhatsApp cliente","💬 WhatsApp cliente","💬 Kunden-WhatsApp","💬 WhatsApp cliente","💬 WhatsApp klant","💬 واتساب العميل","💬 WhatsApp kiliyaan","💬 顾客 WhatsApp"],["✅ Confirmer","✅ Confirm","✅ Confirmar","✅ Confirmar","✅ Bestätigen","✅ Conferma","✅ Bevestigen","✅ تأكيد","✅ Dëggal","✅ 确认"],["✕ Refuser","✕ Decline","✕ Rechazar","✕ Recusar","✕ Ablehnen","✕ Rifiuta","✕ Weigeren","✕ رفض","✕ Bañ","✕ 拒绝"],["Aucune demande de réservation pour le moment.","No booking requests yet.","Aún no hay solicitudes de reserva.","Ainda não há pedidos de reserva.","Noch keine Buchungsanfragen.","Nessuna richiesta di prenotazione.","Nog geen reserveringsaanvragen.","لا توجد طلبات حجز حتى الآن.","Amagul laaju rezervaasiyoŋ léegi.","暂无预约申请。"],["✅ Réservation confirmée.","✅ Booking confirmed.","✅ Reserva confirmada.","✅ Reserva confirmada.","✅ Buchung bestätigt.","✅ Prenotazione confermata.","✅ Reservering bevestigd.","✅ تم تأكيد الحجز.","✅ Dëggal nañu rezervaasiyoŋ bi.","✅ 预约已确认。"],["✅ Demande refusée.","✅ Request declined.","✅ Solicitud rechazada.","✅ Pedido recusado.","✅ Anfrage abgelehnt.","✅ Richiesta rifiutata.","✅ Aanvraag geweigerd.","✅ تم رفض الطلب.","✅ Bañ nañu laaj bi.","✅ 申请已拒绝。"],["Chargement…","Loading…","Cargando…","A carregar…","Lädt…","Caricamento…","Laden…","جارٍ التحميل…","Yeb bi di dox…","加载中…"],["Aucun créneau pour ce jour.","No time slots for this day.","No hay horarios para este día.","Sem horários neste dia.","Keine Termine für diesen Tag.","Nessun orario per questo giorno.","Geen tijdsloten voor deze dag.","لا توجد مواعيد لهذا اليوم.","Amul waxtu ci bés bii.","当天没有时段。"],["✅ Créneau mis à jour.","✅ Slot updated.","✅ Horario actualizado.","✅ Horário atualizado.","✅ Termin aktualisiert.","✅ Orario aggiornato.","✅ Tijdslot bijgewerkt.","✅ تم تحديث الموعد.","✅ Yeesal nañu waxtu bi.","✅ 时段已更新。"],["⚠️ Connecte-toi comme propriétaire.","⚠️ Sign in as owner.","⚠️ Inicia sesión como propietario.","⚠️ Entra como proprietário.","⚠️ Als Inhaber anmelden.","⚠️ Accedi come proprietario.","⚠️ Meld je aan als eigenaar.","⚠️ سجّل الدخول بصفتك المالك.","⚠️ Duggal ni boroom bi.","⚠️ 请以业主身份登录。"],["⚠️ Sélectionne un lundi.","⚠️ Select a Monday.","⚠️ Selecciona un lunes.","⚠️ Selecione uma segunda-feira.","⚠️ Wählen Sie einen Montag.","⚠️ Seleziona un lunedì.","⚠️ Kies een maandag.","⚠️ اختر يوم الاثنين.","⚠️ Tànnal Altine.","⚠️ 请选择星期一。"],["⚠️ Choisis des jours et des heures différentes.","⚠️ Choose different days and times.","⚠️ Elige días y horas diferentes.","⚠️ Escolha dias e horários diferentes.","⚠️ Wählen Sie unterschiedliche Tage und Zeiten.","⚠️ Scegli giorni e orari diversi.","⚠️ Kies verschillende dagen en tijden.","⚠️ اختر أيامًا وأوقاتًا مختلفة.","⚠️ Tànnal bés ak waxtu yu wuute.","⚠️ 请选择不同的日期和时间。"],["Enregistrement des seuls créneaux nouveaux…","Saving new slots only…","Guardando solo horarios nuevos…","A guardar apenas novos horários…","Nur neue Termine werden gespeichert…","Salvataggio dei soli nuovi orari…","Alleen nieuwe tijdsloten opslaan…","جارٍ حفظ المواعيد الجديدة فقط…","Denc waxtu yu bees yi rekk…","仅保存新增时段…"],["Impossible d’ouvrir la semaine.","Unable to open the week.","No se pudo abrir la semana.","Não foi possível abrir a semana.","Woche konnte nicht geöffnet werden.","Impossibile aprire la settimana.","Kan de week niet openen.","تعذّر فتح الأسبوع.","Mënuloo ubbi ayu-bés bi.","无法开放本周。"],[" créneau(x) créé(s). "," slot(s) created. "," horario(s) creados. "," horário(s) criados. "," Termin(e) erstellt. "," orari creati. "," tijdslot(en) aangemaakt. "," مواعيد أُنشئت. "," waxtu yu bees yu ñu def. "," 个时段已创建。"],[" créneau(x) existant(s) préservé(s)."," existing slot(s) preserved."," horario(s) existentes conservados."," horários existentes preservados."," vorhandene Termine bleiben erhalten."," orari esistenti conservati."," bestaande tijdsloten behouden."," مواعيد حالية محفوظة."," waxtu yi amoon des nañu."," 个现有时段保持不变。"],["Aucun accès propriétaire pour cette fiche.","No owner access for this profile.","Sin acceso propietario para esta ficha.","Sem acesso do proprietário para este perfil.","Kein Inhaberzugang für dieses Profil.","Nessun accesso proprietario per questa scheda.","Geen eigenaarstoegang voor dit profiel.","لا يوجد دخول مالك لهذه الصفحة.","Amul duggub boroom ci fich bii.","该商家资料没有业主访问权限。"],["✅ Profil BEAUTY mis à jour.","✅ BEAUTY profile updated.","✅ Perfil BEAUTY actualizado.","✅ Perfil BEAUTY atualizado.","✅ BEAUTY-Profil aktualisiert.","✅ Profilo BEAUTY aggiornato.","✅ BEAUTY-profiel bijgewerkt.","✅ تم تحديث ملف BEAUTY.","✅ Yeesal nañu fichu BEAUTY.","✅ BEAUTY 商家资料已更新。"],["Connecté : ","Signed in: ","Conectado: ","Ligado: ","Angemeldet: ","Connesso: ","Aangemeld: ","متصل: ","Dugg na: ","已登录："],["propriétaire","owner","propietario","proprietário","Inhaber","proprietario","eigenaar","المالك","boroom","业主"],["Brushing","Blow-dry","Peinado","Brushing","Föhnen","Piega","Föhnen","تصفيف","Brushing","吹发造型"],["Langue","Language","Idioma","Idioma","Sprache","Lingua","Taal","اللغة","Làkk","语言"],["DIGIY BEAUTY · ACCÈS PRO","DIGIY BEAUTY · OWNER ACCESS","DIGIY BEAUTY · ACCESO PRO","DIGIY BEAUTY · ACESSO PRO","DIGIY BEAUTY · INHABERZUGANG","DIGIY BEAUTY · ACCESSO PRO","DIGIY BEAUTY · EIGENAARSTOEGANG","DIGIY BEAUTY · دخول المهني","DIGIY BEAUTY · DUGGUB BOROOM","DIGIY BEAUTY · 业主入口"],["DIGIY BEAUTY · GESTION","DIGIY BEAUTY · MANAGEMENT","DIGIY BEAUTY · GESTIÓN","DIGIY BEAUTY · GESTÃO","DIGIY BEAUTY · VERWALTUNG","DIGIY BEAUTY · GESTIONE","DIGIY BEAUTY · BEHEER","DIGIY BEAUTY · الإدارة","DIGIY BEAUTY · SAYTU","DIGIY BEAUTY · 管理"]];
 const phrase=new Map(); const reverse=new Map();
 for(const row of rows){if(row.length!==10||phrase.has(row[0]))throw Error("Invalid WORLD10 BEAUTY "+row[0]);phrase.set(row[0],row);for(const value of row){if(!reverse.has(value))reverse.set(value,row);}}
 let lang=new URLSearchParams(location.search).get("lang");
 if(!langs.includes(lang)){try{lang=localStorage.getItem("digiy_beauty_pro_lang")}catch(_){}}
 if(!langs.includes(lang))lang="fr";
 const t=text=>{const row=phrase.get(text);return row?row[langs.indexOf(lang)]:text};

 const originals=new WeakMap(), attrOriginals=new WeakMap();
 function businessValue(parent){
   const title=parent.closest("#title");
   if(title && !reverse.has(title.textContent.trim()))return true; // nom réel du salon, intouchable
   return !!parent.closest(".bookingName, .bookingMeta, .bookingName *, .bookingMeta *, input, textarea, [data-owned]");
 }
 function translateDynamic(original,parent){
   const value=original.trim();
   const row=reverse.get(value);
   if(row) return row[langs.indexOf(lang)];
   const connected=phrase.get("Connecté : ");
   for(const prefix of connected){
     if(value.startsWith(prefix)){
       return connected[langs.indexOf(lang)]+value.slice(prefix.length);
     }
   }
   // Les nombres de créneaux sont des valeurs métier. Seuls leurs libellés sont traduits.
   if(parent.id==="weekMsg"){
     const m=value.match(/^✅ (\d+) créneau\(x\) créé\(s\)\. (\d+) créneau\(x\) existant\(s\) préservé\(s\)\.$/);
     if(m){
       return "✅ "+m[1]+t(" créneau(x) créé(s). ")+m[2]+t(" créneau(x) existant(s) préservé(s).");
     }
   }
   return value;
 }
 function translateNode(node){
   const parent=node?.parentElement;
   if(!parent||parent.closest("script,style,noscript,code")||businessValue(parent))return;
   const current=node.nodeValue;
   let snapshot=originals.get(node);
   if(!snapshot || current!==snapshot.last){
     snapshot={original:current,last:current};
     originals.set(node,snapshot);
   }
   const original=snapshot.original;
   const leading=(original.match(/^\s*/)||[""])[0];
   const trailing=(original.match(/\s*$/)||[""])[0];
   const value=original.trim();
   if(!value)return;
   const translated=translateDynamic(original,parent);
   const next=leading+translated+trailing;
   if(current!==next){snapshot.last=next;node.nodeValue=next}
 }
 function translateAttrs(){
   const attrs=["placeholder","aria-label","title"];
   for(const attr of attrs){
     document.querySelectorAll("["+attr+"]").forEach(el=>{
       if(el.closest("[data-owned]"))return;
       const current=el.getAttribute(attr);
       if(!current)return;
       let prev=attrOriginals.get(el);
       if(!prev){prev={};attrOriginals.set(el,prev)}
       let snap=prev[attr];
       if(!snap || snap.last!==current) snap=prev[attr]={original:current,last:current};
       const row=reverse.get(snap.original);
       if(!row)return;
       const next=row[langs.indexOf(lang)];
       if(current!==next){snap.last=next;el.setAttribute(attr,next)}
     });
   }
 }
 function keepLanguageInLinks(){
   document.querySelectorAll('a[href]').forEach(a=>{
     const current=a.getAttribute("href");
     if(!current||current.startsWith("#")||current.startsWith("javascript:"))return;
     let url;
     try{url=new URL(current,location.href)}catch(_){return}
     if(url.origin!==location.origin)return;
     if(url.searchParams.get("lang")===lang)return;
     url.searchParams.set("lang",lang);
     a.setAttribute("href",url.toString());
   });
 }
 function translatePage(){
   document.documentElement.lang=lang;
   document.documentElement.dir=lang==="ar"?"rtl":"ltr";
   const walker=document.createTreeWalker(document.body,NodeFilter.SHOW_TEXT);
   while(walker.nextNode())translateNode(walker.currentNode);
   translateAttrs();
   keepLanguageInLinks();
   const titleRow=reverse.get(document.title);
   if(titleRow)document.title=titleRow[langs.indexOf(lang)];
   const picker=document.getElementById("beautyProWorld10");
   if(picker)picker.value=lang;
 }
 function setLang(next){
   if(!langs.includes(next))return;
   lang=next;
   try{localStorage.setItem("digiy_beauty_pro_lang",lang)}catch(_){}
   const url=new URL(location.href);url.searchParams.set("lang",lang);
   history.replaceState(null,"",url);
   translatePage();
 }
 function boot(){
   const header=document.querySelector("header.top")||document.querySelector("body > .card")||document.querySelector(".card");
   if(header && !document.getElementById("beautyProWorld10")){
     const picker=document.createElement("select");
     picker.id="beautyProWorld10";
     picker.setAttribute("aria-label","Langue");
     picker.style.cssText="max-width:130px;min-height:41px;border:2px solid #ba799f;border-radius:12px;padding:8px;background:white;color:#342333;direction:ltr;font:900 13px system-ui";
     for(let i=0;i<langs.length;i++){
       const option=document.createElement("option");
       option.value=langs[i];option.textContent=names[i];picker.appendChild(option);
     }
     picker.addEventListener("change",()=>setLang(picker.value));
     if(header.matches?.(".card")){picker.style.marginBottom="12px";header.insertBefore(picker,header.firstChild)}
     else header.appendChild(picker);
   }
   translatePage();
   new MutationObserver(()=>translatePage()).observe(document.body,{childList:true,subtree:true,characterData:true});
   window.DIGIY_BEAUTY_PRO_WORLD10={locales:langs.slice(),getLang:()=>lang,setLang,translate:t};
 }
 if(document.readyState==="loading") document.addEventListener("DOMContentLoaded",boot,{once:true});
 else boot();
})();
