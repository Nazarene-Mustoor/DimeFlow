import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/getaway_model.dart';
import '../providers/getaway_provider.dart';
import '../widgets/placeholder_ui.dart';
import 'package:intl/intl.dart';

class GetawayListScreen extends StatefulWidget {
  const GetawayListScreen({Key? key}) : super(key: key);

  @override
  _GetawayListScreenState createState() => _GetawayListScreenState();
}

class _GetawayListScreenState extends State<GetawayListScreen> {

  String searchQuery = ''; // Variable to store search query

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final getawayProvider = Provider.of<GetawayProvider>(context, listen: false);
      final hasData = await getawayProvider.fetchGetaways();

      if (!hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No getaways found!')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Getaways'),
        backgroundColor: const Color(0xFF305038),
        foregroundColor: const Color(0xFFFFD700),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Search Getaways',
                  labelStyle: const TextStyle(color: Colors.black54),
                  prefixIcon: const Icon(Icons.search),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.blueGrey),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: Colors.blueGrey),
                  ),
                ),
                cursorColor: Colors.black54,
                onChanged: (query) {
                  setState(() {
                    searchQuery = query.toLowerCase();
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            // Consumer to listen to getaway provider
            Expanded(
              child: Consumer<GetawayProvider>(
                builder: (context, getawayProvider, _) {
                  if (getawayProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.black,));
                  } else if (getawayProvider.getaways.isEmpty) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Card(
                          margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                          color: const Color(0xFF305038),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 2,
                          child: const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Text(
                                  "🏖 Welcome to Getaway Mode!",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFFD700)),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Keep track of all expenses in your exclusive getaways!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Color(0xFFFFD700),),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const EmptyPlaceholder(
                          message: 'No Getaways Yet!',
                          subtitle: 'Tap the + button to add your first getaway.',
                          icon: Icons.airplane_ticket_sharp,
                        ),
                      ],
                    );
                  } else {
                    // Filter getaways based on search query
                    final filteredGetaways = getawayProvider.getaways.where((getaway) {
                      return getaway.name.toLowerCase().contains(searchQuery);
                    }).toList();

                    if (filteredGetaways.isEmpty) {
                      return const Center(child: Text('No getaways found'));
                    }

                    return ListView.builder(
                      itemCount: filteredGetaways.length,
                      itemBuilder: (context, index) {
                        final getaway = filteredGetaways[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 20),
                            color: Colors.white,
                            child: Dismissible(
                              key: ValueKey(getaway.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                color: Colors.red,
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              onDismissed: (_) {
                                getawayProvider.deleteGetaway(getaway.id);
                              },
                              child: ListTile(

                                title: Text(getaway.name, style: const TextStyle()),
                                subtitle: Text(
                                  'Created: ${DateFormat('MMM dd, yyyy').format(getaway.startDate)}',
                                    style: const TextStyle(),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/getawayExpenses',
                                    arguments: {
                                      'getawayId': getaway.id,
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 80,
        child: BottomAppBar(
          color: const Color(0xFF305038),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/home');
                  }, icon: const Icon(Icons.home_sharp, color: Color(0xFFFFD700),)),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/expenseList');
                  }, icon: const Icon(Icons.paid_sharp, color: Color(0xFFFFD700))),
                  const SizedBox(width: 20,),
                  Transform.translate(
                    offset: const Offset(0, -5),
                    child: FloatingActionButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddGetawayBottomSheet(),
                        );
                      },
                      backgroundColor: const Color(0xFFFFD700),
                      child: const Icon(Icons.add, color: Colors.black,),
                    ),
                  ),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/getawayList');
                  }, icon: const Icon(Icons.tsunami_sharp, color: Color(0xFFFFD700))),
                  const SizedBox(width: 20,),
                  IconButton(onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  }, icon: const Icon(Icons.person_rounded, color: Color(0xFFFFD700),)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// BottomSheet for adding getaway
class AddGetawayBottomSheet extends StatefulWidget {
  const AddGetawayBottomSheet({Key? key}) : super(key: key);

  @override
  State<AddGetawayBottomSheet> createState() => _AddGetawayBottomSheetState();
}

class _AddGetawayBottomSheetState extends State<AddGetawayBottomSheet> {
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _typeController = TextEditingController();
  DateTime _startDate = DateTime.now();  // Default start date (today)
  DateTime _endDate = DateTime.now().add(const Duration(days: 5));  // Default end date (5 days later)

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final getawayProvider = Provider.of<GetawayProvider>(context, listen: false);

    return Stack(
      children: [
        // Background Blur
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  const Center(
                    child: Text(
                      'Add New Getaway',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Getaway Name Input
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      hintText: 'Getaway Name',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  // Location Input
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      hintText: 'Location',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  // Type Input
                  TextField(
                    controller: _typeController,
                    decoration: InputDecoration(
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: Colors.blueGrey,
                          )
                      ),
                      hintText: 'Type (e.g., Leisure, Business, Concert)',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    cursorColor: Colors.black54,
                  ),
                  const SizedBox(height: 20),
                  // Start Date Picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.blueGrey),
                    ),
                    child: ListTile(
                      title: Text('Start Date: ${DateFormat('MMM dd, yyyy').format(_startDate)}', style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.calendar_today,color: Colors.blueGrey),
                      onTap: () async {
                        final selectedStartDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Colors.blueGrey, // Header color
                                hintColor: Colors.blueGrey, // Selected date color
                                colorScheme: const ColorScheme.light(primary: Colors.blueGrey), // Button color
                                buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (selectedStartDate != null && selectedStartDate != _startDate) {
                          setState(() {
                            _startDate = selectedStartDate;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // End Date Picker
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(color: Colors.blueGrey),
                    ),
                    child: ListTile(
                      title: Text('End Date: ${DateFormat('MMM dd, yyyy').format(_endDate)}', style: const TextStyle(color: Colors.grey)),
                      trailing: const Icon(Icons.calendar_today,color: Colors.blueGrey),
                      onTap: () async {
                        final selectedEndDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,  // Make sure the end date is not before the start date
                          lastDate: DateTime(2100),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.light().copyWith(
                                primaryColor: Colors.blueGrey, // Header color
                                hintColor: Colors.blueGrey, // Selected date color
                                colorScheme: const ColorScheme.light(primary: Colors.blueGrey), // Button color
                                buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (selectedEndDate != null && selectedEndDate != _endDate) {
                          setState(() {
                            _endDate = selectedEndDate;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Save Button
                  ElevatedButton(
                    onPressed: () async {
                      if (_nameController.text.trim().isNotEmpty &&
                          _locationController.text.trim().isNotEmpty &&
                          _typeController.text.trim().isNotEmpty) {
                        try {
                          // Create Getaway model
                          final newGetaway = Getaway(
                            id: '',
                            name: _nameController.text.trim(),
                            startDate: _startDate,
                            endDate: _endDate,
                            location: _locationController.text.trim(),
                            type: _typeController.text.trim(),
                          );

                          await getawayProvider.addGetaway(newGetaway);
                          Navigator.pop(context);

                          // After successful save, show a success SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Getaway saved successfully!', style: TextStyle(color: Color(0xFFFFD700),),),
                              backgroundColor: Color(0xFF305038),
                            ),
                          );
                        } catch (e) {
                          // If error happens, show error SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to save getaway. Please try again.', style: TextStyle(color: Color(0xFFFFD700),)),
                              backgroundColor: Color(0xFF305038),
                            ),
                          );
                        }
                      } else {
                        // If fields are missing
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill all fields', style: TextStyle(color: Color(0xFFFFD700),)),
                            backgroundColor: Color(0xFF305038),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor:   const Color(0xFF305038,),),
                    child: const Text('Save',style: const TextStyle(color: Color(0xFFFFD700),),),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
