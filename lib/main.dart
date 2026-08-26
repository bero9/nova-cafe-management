import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart'; // استدعاء مكتبة هايف
import 'nova.dart'; // استدعاء الكلاسات من الملف الآخر

// السطر السحري الخاص بملف main
part 'main.g.dart';

void main() async {
  // 1. تهيئة فلاتر وهايف قبل تشغيل واجهة التطبيق
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // 2. تسجيل المحولات (سنقوم بتوليدها في الخطوة القادمة)
  Hive.registerAdapter(PurchaseItemAdapter());
  Hive.registerAdapter(UserSessionAdapter());
  Hive.registerAdapter(DailyLogItemAdapter());
  Hive.registerAdapter(SubscriberAdapter());

  // 3. فتح الصناديق (قواعد البيانات المحلية)
  await Hive.openBox<UserSession>('activeSessionsBox');
  await Hive.openBox<DailyLogItem>('dailyLogsBox');
  await Hive.openBox<Subscriber>('subscribersBox');

  runApp(const StudyCafeApp());
}

// ----------------------------------------------------
// نماذج البيانات لـ Hive
// ----------------------------------------------------

@HiveType(typeId: 2) // المعرف رقم 2
class DailyLogItem {
  @HiveField(0)
  final String userName;

  @HiveField(1)
  final String tableNumber;

  @HiveField(2)
  final double totalBill;

  @HiveField(3)
  final double purchasesTotal;

  @HiveField(4)
  final double timeCost;

  @HiveField(5)
  final DateTime date;

  DailyLogItem({
    required this.userName, required this.tableNumber,
    required this.totalBill, required this.purchasesTotal,
    required this.timeCost, required this.date
  });
}

@HiveType(typeId: 3) // المعرف رقم 3
class Subscriber {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final DateTime joinDate;

  @HiveField(3)
  final String type;

  Subscriber({required this.id, required this.name, required this.joinDate, required this.type});

  DateTime get endDate {
    if (type == 'أسبوعي') {
      return joinDate.add(const Duration(days: 7));
    } else {
      return DateTime(joinDate.year, joinDate.month + 1, joinDate.day);
    }
  }
}
class StudyCafeApp extends StatelessWidget {
  const StudyCafeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'كافتيريا الدراسة',
      theme: ThemeData(primarySwatch: Colors.indigo),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 1. جلب الصناديق التي فتحناها لكي نستخدمها
  final activeSessionsBox = Hive.box<UserSession>('activeSessionsBox');
  final dailyLogsBox = Hive.box<DailyLogItem>('dailyLogsBox');
  final subscribersBox = Hive.box<Subscriber>('subscribersBox');

  double currentHourlyRate = 2000.0;

  void _editHourlyRate() {
    final TextEditingController rateController = TextEditingController(text: currentHourlyRate.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات تسعيرة الوقت', style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: rateController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'أدخل سعر الساعة الجديد', suffixText: 'ل.س', icon: Icon(Icons.price_change)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            onPressed: () {
              setState(() => currentHourlyRate = double.tryParse(rateController.text) ?? currentHourlyRate);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تعديل السعر إلى ${currentHourlyRate.toInt()} ل.س للساعة')));
            },
            child: const Text('حفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addNewSession() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController tableController = TextEditingController();
    bool isSubscriberClient = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('إضافة شخص جديد'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: tableController, decoration: const InputDecoration(hintText: 'رقم الطاولة', icon: Icon(Icons.table_restaurant)), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  TextField(controller: nameController, decoration: const InputDecoration(hintText: 'اسم الشخص', icon: Icon(Icons.person))),
                  const SizedBox(height: 15),
                  CheckboxListTile(
                    title: const Text('هذا الزبون يمتلك اشتراك', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                    value: isSubscriberClient,
                    activeColor: Colors.purple,
                    onChanged: (bool? value) => setStateDialog(() => isSubscriberClient = value ?? false),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                ElevatedButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && tableController.text.isNotEmpty) {
                      final newSession = UserSession(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        userName: nameController.text,
                        tableNumber: tableController.text,
                        entryTime: DateTime.now(),
                        isSubscriber: isSubscriberClient,
                      );
                      // التعديل هنا: حفظ الجلسة مباشرة في قاعدة البيانات بدلاً من القائمة
                      activeSessionsBox.put(newSession.id, newSession);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('بدء الجلسة'),
                ),
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(title: const Text('كافتيريا الدراسة', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.storefront, size: 60, color: Colors.white),
                  SizedBox(height: 10),
                  Text('نظام الإدارة والجرد', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.indigo),
              title: const Text('سجل مشتريات اليوم', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                // إرسال البيانات من الصندوق للشاشة
                Navigator.push(context, MaterialPageRoute(builder: (context) => DailyLogScreen(logs: dailyLogsBox.values.toList())));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.green),
              title: const Text('الجرد الإحصائي (الشهر)', style: TextStyle(fontSize: 16)),
              onTap: () {
                Navigator.pop(context);
                // إرسال البيانات من الصندوق للشاشة
                Navigator.push(context, MaterialPageRoute(builder: (context) => MonthlySummaryScreen(logs: dailyLogsBox.values.toList())));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.card_membership, color: Colors.purple),
              title: const Text('سجل المشتركين', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => const SubscribersScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings, color: Colors.blueGrey),
              title: const Text('تسعيرة الوقت', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              subtitle: Text('السعر الحالي: ${currentHourlyRate.toInt()} ل.س/ساعة', style: const TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(context);
                _editHourlyRate();
              },
            ),
          ],
        ),
      ),
      // التعديل هنا: ValueListenableBuilder لمراقبة صندوق الجلسات وتحديث الشاشة فوراً
      body: ValueListenableBuilder<Box<UserSession>>(
        valueListenable: activeSessionsBox.listenable(),
        builder: (context, box, _) {
          final activeSessions = box.values.toList();
          if (activeSessions.isEmpty) {
            return const Center(child: Text('لا يوجد أشخاص حالياً.\nاضغط على + لإضافة زبون.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 0.40,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: activeSessions.length,
            itemBuilder: (context, index) {
              final session = activeSessions[index];
              return TableCard(
                key: ValueKey(session.id),
                session: session,
                hourlyRate: currentHourlyRate,
                onClearTable: (total, purchases, time) {
                  // عند الدفع: نحفظ الفاتورة في الجرد، ونحذف الطاولة من الجلسات النشطة
                  dailyLogsBox.add(DailyLogItem(
                    userName: session.userName,
                    tableNumber: session.tableNumber,
                    totalBill: total,
                    purchasesTotal: purchases,
                    timeCost: time,
                    date: DateTime.now(),
                  ));
                  box.delete(session.id);
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSession,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, size: 30),
      ),
    );
  }
}

class DailyLogScreen extends StatelessWidget {
  final List<DailyLogItem> logs;
  const DailyLogScreen({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<DailyLogItem> todayLogs = logs.where((log) =>
    log.date.year == now.year &&
        log.date.month == now.month &&
        log.date.day == now.day).toList();

    double totalDayIncome = 0, totalDayPurchases = 0, totalDayTime = 0;
    for (var log in todayLogs) {
      totalDayIncome += log.totalBill;
      totalDayPurchases += log.purchasesTotal;
      totalDayTime += log.timeCost;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الجرد اليومي التفصيلي'), backgroundColor: Colors.teal),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), border: const Border(bottom: BorderSide(color: Colors.teal, width: 2))),
            child: Column(
              children: [
                Text('إجمالي صندوق اليوم', style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                Text('${totalDayIncome.toInt()} ل.س', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal)),
                const SizedBox(height: 15),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(children: [const Icon(Icons.local_cafe, color: Colors.orange, size: 20), const SizedBox(width: 5), Text('المشروبات: ${totalDayPurchases.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                    Row(children: [const Icon(Icons.timer, color: Colors.blue, size: 20), const SizedBox(width: 5), Text('الوقت: ${totalDayTime.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                  ],
                ),
                const SizedBox(height: 10),
                Text('عدد زبائن اليوم: ${todayLogs.length} زبون', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              ],
            ),
          ),
          Expanded(
            child: todayLogs.isEmpty
                ? const Center(child: Text('لا توجد فواتير مسجلة لهذا اليوم.', style: TextStyle(fontSize: 16, color: Colors.grey)))
                : ListView.builder(
              padding: const EdgeInsets.only(top: 8),
              itemCount: todayLogs.length,
              itemBuilder: (context, index) {
                final log = todayLogs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.teal, child: Text(log.tableNumber, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text('الزبون: ${log.userName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('وقت الدفع: ${log.date.hour}:${log.date.minute.toString().padLeft(2,'0')}'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${log.totalBill.toInt()} ل.س', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                        Text('مشروبات: ${log.purchasesTotal.toInt()} | وقت: ${log.timeCost.toInt()}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySummaryScreen extends StatelessWidget {
  final List<DailyLogItem> logs;
  const MonthlySummaryScreen({Key? key, required this.logs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double totalIncome = 0, totalFromTime = 0, totalFromPurchases = 0;
    for (var log in logs) {
      totalIncome += log.totalBill;
      totalFromTime += log.timeCost;
      totalFromPurchases += log.purchasesTotal;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('الجرد العام'), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryCard('إجمالي الدخل', totalIncome, Colors.green, Icons.attach_money),
            const SizedBox(height: 10),
            _buildSummaryCard('أرباح المشروبات', totalFromPurchases, Colors.orange, Icons.local_cafe),
            const SizedBox(height: 10),
            _buildSummaryCard('أرباح الوقت (الجلسات)', totalFromTime, Colors.blue, Icons.timer),
            const SizedBox(height: 20),
            Text('عدد الزبائن الكلي: ${logs.length}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text('${amount.toInt()} ل.س', style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
      ),
    );
  }
}

// التعديل هنا: ربط شاشة المشتركين بصندوق المشتركين في قاعدة البيانات
class SubscribersScreen extends StatefulWidget {
  const SubscribersScreen({Key? key}) : super(key: key);

  @override
  State<SubscribersScreen> createState() => _SubscribersScreenState();
}

class _SubscribersScreenState extends State<SubscribersScreen> {
  final subscribersBox = Hive.box<Subscriber>('subscribersBox');

  void _addNewSubscriber() {
    final TextEditingController nameController = TextEditingController();
    String selectedType = 'شهري';

    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text('إضافة مشترك جديد', style: TextStyle(color: Colors.purple)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(hintText: 'اسم المشترك', icon: Icon(Icons.person))),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.grey),
                          const SizedBox(width: 15),
                          const Text('نوع الاشتراك: '),
                          const SizedBox(width: 10),
                          DropdownButton<String>(
                            value: selectedType,
                            items: ['أسبوعي', 'شهري'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                            onChanged: (newValue) => setStateDialog(() => selectedType = newValue!),
                          ),
                        ],
                      )
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          final newSub = Subscriber(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            name: nameController.text,
                            joinDate: DateTime.now(),
                            type: selectedType,
                          );
                          // حفظ المشترك في قاعدة البيانات
                          subscribersBox.put(newSub.id, newSub);
                          Navigator.pop(context);
                        }
                      },
                      child: const Text('حفظ', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                );
              }
          );
        }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المشتركين'), backgroundColor: Colors.purple),
      body: ValueListenableBuilder<Box<Subscriber>>(
          valueListenable: subscribersBox.listenable(),
          builder: (context, box, _) {
            final subscribers = box.values.toList();
            if (subscribers.isEmpty) {
              return const Center(child: Text('لا يوجد مشتركين حالياً.\nاضغط على + لإضافة مشترك.', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: Colors.grey)));
            }
            return ListView.builder(
              itemCount: subscribers.length,
              itemBuilder: (context, index) {
                final sub = subscribers[index];
                return Dismissible(
                  key: ValueKey(sub.id),
                  direction: DismissDirection.startToEnd,
                  background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete_forever, color: Colors.white, size: 35)),
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          content: Text('هل أنت متأكد من رغبتك بحذف المشترك "${sub.name}" نهائياً؟'),
                          actions: [
                            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(context).pop(true), child: const Text('حذف المشترك', style: TextStyle(color: Colors.white))),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    box.delete(sub.id); // حذفه من قاعدة البيانات نهائياً
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم حذف المشترك ${sub.name} بنجاح'), backgroundColor: Colors.redAccent, duration: const Duration(seconds: 2)));
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8.0),
                    elevation: 3,
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: sub.type == 'شهري' ? Colors.purple : Colors.orange, child: const Icon(Icons.star, color: Colors.white)),
                      title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      subtitle: Text('بدأ: ${sub.joinDate.year}/${sub.joinDate.month}/${sub.joinDate.day}\nينتهي: ${sub.endDate.year}/${sub.endDate.month}/${sub.endDate.day}', style: const TextStyle(height: 1.5)),
                      trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: sub.type == 'شهري' ? Colors.purple.withOpacity(0.1) : Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Text(sub.type, style: TextStyle(fontWeight: FontWeight.bold, color: sub.type == 'شهري' ? Colors.purple : Colors.orange))),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            );
          }
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addNewSubscriber, backgroundColor: Colors.purple, child: const Icon(Icons.add, size: 30)),
    );
  }
}