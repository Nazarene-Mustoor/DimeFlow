import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/currency_provider.dart';
import 'currency_data.dart';

class SettingsDrawer extends StatelessWidget {
  const SettingsDrawer({super.key});

  void _showCurrencySelectorDialog(BuildContext context) {
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);

    String? customSymbol;

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            title: const Text('Select Currency'),
            content: SizedBox(
              height: 300,
              width: double.maxFinite,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: currencyList.length + 1, // +1 for 'Custom'
                      itemBuilder: (context, index) {
                        if (index == currencyList.length) {
                          // Custom input
                          return ListTile(
                            title: const Text('Custom Currency'),
                            trailing: const Icon(Icons.edit),
                            onTap: () {
                              Navigator.of(context).pop(); // Close this dialog
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text('Enter Custom Currency Symbol'),
                                    content: TextField(
                                      decoration: const InputDecoration(
                                        focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.blueGrey,
                                            )
                                        ),
                                        enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.blueGrey,
                                            )
                                        ),
                                        hintText: 'Currency Symbol',
                                        hintStyle: TextStyle(color: Colors.grey),
                                      ),
                                      cursorColor: Colors.black54,
                                      onChanged: (val) => customSymbol = val.trim(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancel', style: TextStyle(color: Colors.black),),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          if (customSymbol != null && customSymbol!.isNotEmpty) {
                                            currencyProvider.changeCurrency(customSymbol!);
                                            Navigator.of(context).pop();
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Currency set to $customSymbol')),
                                            );
                                          }
                                        },
                                        child: const Text('Save',style: TextStyle(color: Colors.black),),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        }

                        final currency = currencyList[index];
                        final isSelected = currencyProvider.currency == currency['symbol'];

                        return ListTile(
                          title: Text('${currency['name']} (${currency['code']})', style: const TextStyle(color: Colors.black)),
                          leading: Text(currency['symbol'] ?? '', style: const TextStyle(color: Colors.black)),
                          trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                          selected: isSelected,
                          selectedTileColor: Colors.black.withOpacity(0.1),
                          onTap: () {
                            currencyProvider.changeCurrency(currency['symbol']!);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Currency changed to ${currency['name']}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                const DrawerHeader(
                  decoration: BoxDecoration(color: Color(0xFF305038,),),
                  padding: EdgeInsets.fromLTRB(16, 50, 16, 20),
                  child: Text('Settings', style: TextStyle(color:  Color(0xFFFFD700), fontSize: 30)),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.brightness_6),
                  title: const Text('Theme'),
                  trailing: const Text('Coming Soon!', style: TextStyle(color: Colors.orange)),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.currency_exchange),
                  title: const Text('Currency Selection'),
                  onTap: () => _showCurrencySelectorDialog(context),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: const Text('Notification Preferences'),
                  trailing: const Text('Coming Soon!', style: TextStyle(color: Colors.orange)),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.g_translate_sharp),
                  title: const Text('Language'),
                  trailing: const Text('Coming Soon!', style: TextStyle(color: Colors.orange)),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Personalisation'),
                  subtitle: const Text('Coming Soon!', style: TextStyle(color: Colors.orange)),
                  trailing: const Tooltip(
                    message: 'Will let you tweak chart colors, category styles, and more.',
                    child: Icon(Icons.info_outline),
                  ),
                  onTap: () {},
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Logout is **outside** the ListView, so it stays at bottom
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () async {
              final shouldLogout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.white,
                  title: const Text("Confirm Logout?"),
                  content: const Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Logout", style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldLogout == true) {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              }
            },

          ),

          const SizedBox(height: 20), // Optional padding at bottom
        ],
      ),
    );
  }
}

