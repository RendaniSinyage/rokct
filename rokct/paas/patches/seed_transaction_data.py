import frappe
from frappe.model.document import Document

def execute():
    if frappe.local.site != 'juvo.tenant.rokct.ai':
        return

    users_data = {
        1: ("South", "River"), 101: ("Juvo", "Admin"), 107: ("Waiter", "Waiter"),
        109: ("kfc", "2"), 119: ("South", "River"), 129: ("Axel", "Group"),
        130: ("boxer", "liquor"), 133: ("bosya", None), 134: ("Nekhavhambe", "Ndanganeni"),
        147: ("south@gosouth.app", None), 148: ("Frank", "Mudau"), 151: ("Mr.", "R"),
        152: ("pedro", "moreno"), 210: ("TUMI", "MABOLABOLA"), 240: ("Rendani", "Sinyage"),
        241: ("default", "customer"), 242: ("Mike", "Mabudu"), 244: ("Picker", "GOsouth"),
        245: ("Khodani", "Mudau"), 264: ("Doreen", "Hart"), 265: ("Co", "Ook"),
        266: ("Cnx", "Play"), 268: ("Nuage", "Laboratoire"), 570: ("Dendi", "4890"),
        575: ("dydatagrip", None), 576: ("Mahmud", "Mamatov"), 702: ("Rendani", "Sinyage"),
        758: ("Sandile", "Mpala"), 782: ("Janet", "Musendekwa"), 783: ("Malekgo", "Rapanyane"),
        784: ("Pinky", "Mashula"), 785: ("Grace", "Zhou"), 787: ("Jordan", "Ngobeni"),
        788: ("south", "juvo"), 792: ("Lesley", "Matunga"), 793: ("Mujomana", "Mulaudzi"),
        794: ("Jayden", "Ramarumo"), 795: ("Tamuona", "Taruberekera"), 796: ("Ipfi", "Nengome"),
        797: ("Alfred", "Ndlovu"), 801: ("Neo", "Moyana"), 803: ("Mpashi", "Mulutanyi"),
        804: ("Judas", "Makashe"), 805: ("Bestor", "Marufu"), 807: ("Andrew", "Sibanda"),
        827: ("Haykal", "Ahmed"), 828: ("Daphney", "Masindi"), 829: ("Unarine", "Masutha"),
        831: ("Prince", "Mpho"), 832: ("Kwinda", "Ronewa"), 839: ("Charles", "Patlane"),
        840: ("Samson", "Makushu"), 841: ("Judah", "Rasimpi"), 842: ("Rudolf", "Orifha"),
        845: ("Siphokazi", "Maqanda"), 846: ("Mpho", "Phiri"), 847: ("Eric", "Sediela"),
        848: ("Matimu", "Hlungwani"), 849: ("Tafadza", "Kumbula"), 850: ("Fhatuwani", "Munzhelele"),
        851: ("Thanyani", "Maila"), 852: ("Caswell", "Nkhatha"), 858: ("Jimmy", "Mmaboloka"),
        859: ("Ezex", "Dube"), 862: ("Enos", "Zvokoumba"), 863: ("Linah", "Makgosa"),
        864: ("Tshimangadzo", "Ramalwa"), 866: ("wait", "er"), 868: ("Masilo", "Sebola"),
        869: ("Terrence", "Mabila"), 870: ("Russell", "Ramphabana"), 871: ("Constance", "Khunwana"),
        872: ("Joseph", "Makgwathana"), 873: ("isaiah", "mabolabola"), 874: ("Thembi's", "Kitchen"),
        875: ("Joseph", "Mulaudzi"), 876: ("Ali", "Leman"), 877: ("Chamunorwa", "Mazarura"),
        878: ("Itani", "Mbedzi"), 882: ("Sandile", "Mpala"), 883: ("Pablo", "Saidi"),
        890: ("Masindi", "Sibula"), 891: ("Solly", "Ndou"),
    }

    payment_gateways = {
        1: "Cash", 2: "Stripe", 3: "RazorPay", 4: "Paystack",
        5: "FlutterWave", 7: "Mollie", 8: "PayPal", 12: "MercadoPago"
    }

    transactions_data = [
        {'id': 1500, 'payable_type': 'App\\Models\\Order', 'payable_id': 1, 'price': 2131.33, 'user_id': 119, 'payment_sys_id': 1, 'status': 'paid', 'created_at': '2023-04-18 21:08:49'},
        {'id': 1509, 'payable_type': 'App\\Models\\Order', 'payable_id': 2, 'price': 31.33, 'user_id': 107, 'payment_sys_id': 4, 'status': 'progress', 'created_at': '2023-03-26 17:37:44'},
        {'id': 1525, 'payable_type': 'App\\Models\\Order', 'payable_id': 3, 'price': 5, 'user_id': 107, 'payment_sys_id': 5, 'status': 'canceled', 'created_at': '2023-04-18 21:08:49'},
    ]

    for trans in transactions_data:
        if trans['payable_type'] != 'App\\Models\\Order':
            continue

        pe_name = f"PE-{trans['id']}"
        if frappe.db.exists("Payment Entry", pe_name):
            continue

        user_id = trans['user_id']
        if user_id not in users_data:
            continue

        first_name, last_name = users_data[user_id]
        customer_name = f"{first_name} {last_name}".strip() if last_name else first_name

        customer = frappe.get_value("Customer", {"customer_name": customer_name}, "name")
        if not customer:
            continue

        order_name = f"ORD-{trans['payable_id']}"
        if not frappe.db.exists("Order", order_name):
            continue

        payment_gateway_name = payment_gateways.get(trans['payment_sys_id'])
        if not payment_gateway_name:
            continue

        # payment gateway account is not automatically created, so let's check
        if not frappe.db.exists("Payment Gateway Account", payment_gateway_name):
             pg_account = frappe.get_doc({
                "doctype": "Payment Gateway Account",
                "account": f"Cash - _TC",
                "payment_gateway": payment_gateway_name,
            }).insert(ignore_permissions=True)

        pe = frappe.new_doc("Payment Entry")
        pe.payment_type = "Receive"
        pe.party_type = "Customer"
        pe.party = customer
        pe.paid_amount = trans['price']
        pe.received_amount = trans['price']
        pe.posting_date = trans['created_at'].split(" ")[0]

        pe.append("references", {
            "reference_doctype": "Order",
            "reference_name": order_name,
            "total_amount": trans['price'],
            "outstanding_amount": 0,
            "allocated_amount": trans['price']
        })

        pe.insert(ignore_permissions=True)

        if trans['status'] == 'paid':
            pe.submit()
        elif trans['status'] == 'canceled':
            pe.cancel()

    frappe.db.commit()