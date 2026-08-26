import 'package:flutter/material.dart';
import 'package:hive/hive.dart'; // الإضافة الجديدة: استدعاء مكتبة هايف

// هذا السطر ضروري جداً (سيعطي خطأ أحمر مؤقتاً فلا تقلق، سنعالجه في الخطوة القادمة)
part 'nova.g.dart';

// ----------------------------------------------------
// 1. تعريف نماذج البيانات لـ Hive
// ----------------------------------------------------

@HiveType(typeId: 0) // المعرف رقم 0
class PurchaseItem {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double price;

  PurchaseItem({required this.name, required this.price});
}

@HiveType(typeId: 1) // المعرف رقم 1
class UserSession {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String userName;

  @HiveField(2)
  String tableNumber;

  @HiveField(3)
  DateTime entryTime;

  @HiveField(4)
  bool isSubscriber;

  @HiveField(5)
  List<PurchaseItem> purchases;

  UserSession({
    required this.id,
    required this.userName,
    required this.tableNumber,
    required this.entryTime,
    this.isSubscriber = false,
    List<PurchaseItem>? purchases,
  }) : purchases = purchases ?? [];
}

// ----------------------------------------------------
// 2. واجهة كارت الطاولة (كما هي بدون تغيير)
// ----------------------------------------------------

class TableCard extends StatefulWidget {
  final UserSession session;
  final double hourlyRate;
  final void Function(double totalBill, double purchasesTotal, double timeCost) onClearTable;

  const TableCard({
    Key? key,
    required this.session,
    required this.hourlyRate,
    required this.onClearTable
  }) : super(key: key);

  @override
  State<TableCard> createState() => _TableCardState();
}

class _TableCardState extends State<TableCard> {
  final TextEditingController itemController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  void _editSessionDialog() {
    final TextEditingController nameCtrl = TextEditingController(text: widget.session.userName);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(widget.session.entryTime);
    List<PurchaseItem> tempPurchases = List.from(widget.session.purchases);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setStateDialog) {
              return AlertDialog(
                title: const Text('تعديل الجلسة', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'تعديل اسم الزبون', icon: Icon(Icons.person))),
                      const SizedBox(height: 15),
                      ListTile(
                        contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time, color: Colors.grey), title: const Text('تعديل وقت الدخول'),
                        subtitle: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        trailing: const Icon(Icons.edit, size: 18),
                        onTap: () async {
                          TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                          if (picked != null) setStateDialog(() => selectedTime = picked);
                        },
                      ),
                      const Divider(),
                      const Text('تعديل المشتريات:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      if (tempPurchases.isEmpty) const Text('لا توجد مشتريات حالياً', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ...tempPurchases.map((item) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('☕ ${item.name} (${item.price.toInt()})', style: const TextStyle(fontSize: 13)),
                            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setStateDialog(() => tempPurchases.remove(item))),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.grey))),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () {
                      setState(() {
                        widget.session.userName = nameCtrl.text;
                        widget.session.entryTime = DateTime(widget.session.entryTime.year, widget.session.entryTime.month, widget.session.entryTime.day, selectedTime.hour, selectedTime.minute);
                        widget.session.purchases = tempPurchases;
                      });
                      // الحفظ في قاعدة البيانات بعد التعديل
                      Hive.box<UserSession>('activeSessionsBox').put(widget.session.id, widget.session);
                      Navigator.pop(context);
                    },
                    child: const Text('حفظ التعديلات', style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            }
        );
      },
    );
  }

  void _addPurchase() {
    if (itemController.text.isNotEmpty && priceController.text.isNotEmpty) {
      setState(() {
        widget.session.purchases.add(PurchaseItem(name: itemController.text, price: double.tryParse(priceController.text) ?? 0.0));
      });
      // الحفظ في قاعدة البيانات فور إضافة مشروب
      Hive.box<UserSession>('activeSessionsBox').put(widget.session.id, widget.session);
      itemController.clear();
      priceController.clear();
    }
  }
  void _calculateBill() {
    final checkoutTime = DateTime.now();
    final double hoursSpent = checkoutTime.difference(widget.session.entryTime).inMinutes / 60.0;

    final double chargedHours = hoursSpent > 6.0 ? 6.0 : hoursSpent;
    final double timeCost = widget.session.isSubscriber ? 0.0 : (chargedHours * widget.hourlyRate);

    double purchasesTotal = 0;
    for (var item in widget.session.purchases) {
      purchasesTotal += item.price;
    }

    final double totalBill = timeCost + purchasesTotal;
    final TextEditingController finalBillController = TextEditingController(text: totalBill.toInt().toString());

    String subNote = widget.session.isSubscriber ? '(مشترك - إعفاء من تكلفة الوقت)' : '';
    String timeNote = (!widget.session.isSubscriber && hoursSpent > 6.0) ? '(احتساب 6 ساعات كحد أقصى)' : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('فاتورة - طاولة ${widget.session.tableNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'الزبون: ${widget.session.userName} $subNote\n'
                    'الدخول: ${widget.session.entryTime.hour}:${widget.session.entryTime.minute.toString().padLeft(2, '0')}\n'
                    'الخروج: ${checkoutTime.hour}:${checkoutTime.minute.toString().padLeft(2, '0')}\n\n'
                    'الوقت الفعلي: ${hoursSpent.toStringAsFixed(2)} ساعة\n'
                    'الوقت المحتسب: ${chargedHours.toStringAsFixed(2)} ساعة\n$timeNote\n'
                    'تكلفة الوقت: ${timeCost.toInt()} \n'
                    'إجمالي المشتريات: $purchasesTotal \n'
                    '-------------------------',
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 15),
              const Text('الحساب النهائي:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              const SizedBox(height: 5),
              TextField(
                controller: finalBillController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true, suffixText: 'ل.س'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء التحديث', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () {
              double finalEditedBill = double.tryParse(finalBillController.text) ?? totalBill;
              Navigator.pop(context);
              widget.onClearTable(finalEditedBill, purchasesTotal, timeCost);
            },
            child: const Text('دفع وإخلاء', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: widget.session.isSubscriber ? const BorderSide(color: Colors.purple, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('طاولة: ${widget.session.tableNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
                    Text('🕒 ${widget.session.entryTime.hour}:${widget.session.entryTime.minute.toString().padLeft(2, '0')}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(child: Text('👤 ${widget.session.userName}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                        if (widget.session.isSubscriber)
                          const Padding(padding: EdgeInsets.only(right: 5), child: Icon(Icons.star, color: Colors.purple, size: 16))
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_square, color: Colors.blueGrey, size: 20),
                    onPressed: _editSessionDialog,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),

              const Divider(),
              const Text('الطلبات:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo, fontSize: 13)),
              ...widget.session.purchases.map((item) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('☕ ${item.name}', style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                  Text('${item.price.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.green)),
                ],
              )).toList(),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: itemController,
                      decoration: const InputDecoration(hintText: 'المشروب', isDense: true, contentPadding: EdgeInsets.all(4)),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(hintText: 'السعر', isDense: true, contentPadding: EdgeInsets.all(4)),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_box, color: Colors.indigo, size: 24),
                    onPressed: _addPurchase,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              SizedBox(
                width: double.infinity,
                height: 35,
                child: ElevatedButton(
                  onPressed: _calculateBill,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('حساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}