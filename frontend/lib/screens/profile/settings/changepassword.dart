// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:trading_bot_app/services/auth_service.dart';

class Changepassword extends StatefulWidget {
  const Changepassword({super.key});
  @override
  State<Changepassword> createState() => _ChangepasswordState();
}

class _ChangepasswordState extends State<Changepassword> {
  bool isOldPasswordVisible = false;
  bool isNewPasswordVisible = false;
  bool isNewPasswordAgainVisible = false;
  TextEditingController oldpassword = TextEditingController();
  TextEditingController newpassword = TextEditingController();
  TextEditingController newpasswordagain = TextEditingController();
  // ignore: unused_field
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Şifre Değiştir'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: oldpassword,
              decoration: InputDecoration(labelText: 'Eski Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.lock_outline,size: 15),
                suffixIcon: IconButton(
                  
                  icon: Icon(isOldPasswordVisible ? Icons.visibility : Icons.visibility_off,size: 15),
                  onPressed: () {
                    setState(() {
                      isOldPasswordVisible = !isOldPasswordVisible;
                    });
                  },
                ),
              ),
              obscureText: isOldPasswordVisible,
              
            ),
            SizedBox(height: 20,),
            TextField(
              controller: newpassword,
              obscureText: isNewPasswordVisible,
              decoration: InputDecoration(labelText: 'Yeni Şifre',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.lock_outline,size: 15),
                suffixIcon: IconButton(
                  
                  icon: Icon(isNewPasswordVisible ? Icons.visibility : Icons.visibility_off,size: 15),
                  onPressed: () {
                    setState(() {
                      isNewPasswordVisible = !isNewPasswordVisible;
                    });
                  },
                ),
              ),
            ),
            SizedBox(height: 20,),
            TextField(
              controller: newpasswordagain,
              obscureText: isNewPasswordAgainVisible,
              decoration: InputDecoration(labelText: 'Yeni Şifre (Tekrar)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                prefixIcon: Icon(Icons.lock_outline,size: 15),
                suffixIcon: IconButton(
                  
                  icon: Icon(isNewPasswordAgainVisible ? Icons.visibility : Icons.visibility_off,size: 15),
                  onPressed: () {
                    setState(() {
                      isNewPasswordAgainVisible = !isNewPasswordAgainVisible;
                    });
                  },
                ),
              ), 
            ),
            SizedBox(height: 20),
            ElevatedButton(
              
              onPressed: () async {

                try {
                  await AuthService().updatePassword(
                    email: AuthService().getCurrentUser()?.email ?? '',
                    oldpassword: oldpassword.text,
                    newpassword: newpassword.text
                  );

                  if(mounted ){
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Şifre başarıyla güncellendi!"))
                    );
                    Navigator.pop(context); 
                  }
                }catch (e) {
                  if(mounted){
                    ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red), 
                    );
                  }
                }finally {
                  if (mounted) {
                    setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                backgroundColor: Colors.greenAccent.withValues(alpha: 0.8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20),),
              ),
              child: Text('Şifre Değiştir',style: TextStyle(fontSize: 16,color: Colors.white),),

            ),
          ],
        ),
      ),
    );
  }
}
