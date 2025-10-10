# Copyright (c) 2025 ROKCT Holdings
# For license information, please see license.txt
import frappe
import requests
from datetime import timedelta
from frappe.utils import now_datetime, get_datetime

# ------------------------------------------------------------------------------
# Daily Job (General)
# ------------------------------------------------------------------------------

def manage_daily_tenders():
    """
    Fetches new tenders, updates existing ones, and removes expired tenders.
    This is a general task that can run on any site.
    """
    print("Running Daily Tender Management Job...")

    # 1. Fetch new tender data
    _fetch_and_upsert_tenders()

    # 2. Delete expired tenders
    _delete_expired_tenders()

    print("Daily Tender Management Job Complete.")


def _format_datetime_str(datetime_obj):
    """
    Formats a datetime object into a string ('YYYY-MM-DD HH:MM:SS')
    for database insertion, stripping any timezone info.
    """
    if not datetime_obj:
        return None
    return datetime_obj.strftime('%Y-%m-%d %H:%M:%S')


def _fetch_and_upsert_tenders():
    """
    Fetches tender data from the eTenders API, parses it, and upserts it
    into the Tender doctype, linking to related filter doctypes.
    """
    etenders_api_url = frappe.conf.get("etenders_api_url")
    if not etenders_api_url:
        frappe.log_error("`etenders_api_url` not set in site_config.json. Skipping tender fetch.", "Tender API Fetch Failed")
        return

    page_number = 1
    page_size = 100  # As per API recommendation
    total_upserted = 0

    to_date = now_datetime()
    from_date = to_date - timedelta(days=1)

    params = {
        "dateFrom": from_date.strftime('%Y-%m-%d'),
        "dateTo": to_date.strftime('%Y-%m-%d'),
        "PageSize": page_size
    }

    while True:
        try:
            params["PageNumber"] = page_number
            response = requests.get(etenders_api_url, params=params, timeout=60)
            response.raise_for_status()
            release_package = response.json()

            releases = release_package.get("releases", [])
            if not releases:
                print("No more releases found on subsequent pages. Ending fetch.")
                break

            for release in releases:
                try:
                    tender_data = release.get("tender", {})
                    if not tender_data or not release.get("ocid"):
                        continue

                    category = _get_linked_doc_name("Tender Category", tender_data.get("mainProcurementCategory"))
                    organ_of_state = _get_linked_doc_name("Organ of State", tender_data.get("procuringEntity", {}).get("name"))
                    tender_type = _get_linked_doc_name("Tender Type", tender_data.get("procurementMethod"))
                    province = _find_province_from_parties(release)

                    tender_doc_data = {
                        "doctype": "Tender",
                        "ocid": release.get("ocid"),
                        "title": tender_data.get("title"),
                        "status": tender_data.get("status"),
                        "publisher_name": release.get("publisher", {}).get("name"),
                        "published_date": _format_datetime_str(get_datetime(release.get("date"))),
                        "tender_start_date": _format_datetime_str(get_datetime(tender_data.get("tenderPeriod", {}).get("startDate"))),
                        "tender_end_date": _format_datetime_str(get_datetime(tender_data.get("tenderPeriod", {}).get("endDate"))),
                        "value_amount": tender_data.get("value", {}).get("amount"),
                        "value_currency": tender_data.get("value", {}).get("currency"),
                        "description": tender_data.get("description"),
                        "tender_category": category,
                        "organ_of_state": organ_of_state,
                        "tender_type": tender_type,
                        "province": province,
                        "esubmission": 1 if "electronicSubmission" in tender_data.get("submissionMethod", []) else 0,
                    }

                    if frappe.db.exists("Tender", {"ocid": tender_doc_data["ocid"]}):
                        doc = frappe.get_doc("Tender", {"ocid": tender_doc_data["ocid"]})
                        doc.update(tender_doc_data)
                        doc.save(ignore_permissions=True)
                    else:
                        doc = frappe.new_doc("Tender")
                        doc.update(tender_doc_data)
                        doc.insert(ignore_permissions=True)

                    total_upserted += 1

                except Exception as e:
                    frappe.log_error(f"Failed to process release {release.get('ocid')}: {e}", "Tender Release Processing Failed")

            page_number += 1

        except requests.exceptions.RequestException as e:
            frappe.log_error(f"API request failed on page {page_number}: {e}", "Tender API Fetch Failed")
            break
        except Exception as e:
            frappe.db.rollback()
            frappe.log_error(frappe.get_traceback(), f"Tender Upsert Failed on page {page_number}")
            break

    frappe.db.commit()
    print(f"Successfully upserted {total_upserted} tenders.")


def _get_linked_doc_name(doctype, value):
    if not value:
        return None

    doctype_field_map = {
        "Tender Category": "category_name",
        "Organ of State": "organ_name",
        "Province": "province_name",
        "Tender Type": "tender_type_name",
    }
    fieldname = doctype_field_map.get(doctype)
    if not fieldname:
        frappe.log_error(f"No field mapping found for Doctype {doctype}", "Tender Linking Error")
        return None
    try:
        return frappe.db.get_value(doctype, {fieldname: value}, "name")
    except Exception:
        frappe.log_error(f"Could not find matching document for {doctype} with value '{value}'", "Tender Linking Warning")
        return None

def _find_province_from_parties(release):
    if not release or not release.get("parties"):
        return None

    buyer = release.get("buyer", {})
    buyer_name = buyer.get("name")
    if not buyer_name:
        return None

    for party in release.get("parties", []):
        if party.get("name") == buyer_name:
            region = party.get("address", {}).get("region")
            if region:
                return _get_linked_doc_name("Province", region)
    return None


def _delete_expired_tenders():
    from frappe.utils import getdate, nowdate
    try:
        today = getdate(nowdate())
        expired_tenders = frappe.get_all("Tender",
            filters={"tender_end_date": ["<", today]},
            fields=["name"]
        )

        if not expired_tenders:
            print("No expired tenders to delete.")
            return

        for tender in expired_tenders:
            frappe.delete_doc("Tender", tender.name, ignore_permissions=True, force=True)

        frappe.db.commit()
        print(f"Successfully deleted {len(expired_tenders)} expired tenders.")
    except Exception as e:
        frappe.db.rollback()
        frappe.log_error(frappe.get_traceback(), "Expired Tender Deletion Failed")

