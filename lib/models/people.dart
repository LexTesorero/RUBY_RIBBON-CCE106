class Customer {
  final String id;
  String name;
  final String email;
  String password;
  String contact;
  String address;

  Customer({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.contact,
    required this.address,
  });
}

class StaffAccount {
  final String id;
  final String name;
  final String email;
  final String password;

  const StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });
}