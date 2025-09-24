# Architectural Notes for Juvo Backend Conversion

This document records the high-level architectural decisions and business rules for the Juvo platform as it is being converted to Frappe.

## Single-Company Multi-Vendor Model

This is the core architectural pattern for the platform.

- **All platform transactions (Sales, Payments, etc.) will happen in the single, default `Company`** that belongs to the platform owner.
- **Each vendor on the platform will be represented by a new `Seller` doctype.** This doctype will link to the seller's `User` account and the specific `Warehouse` they are assigned to within the platform owner's company.
- **Sellers will still have their own `Company` doctype** for their own off-platform accounting, but it will not be used for platform transactions.

### Transaction and Commission Flow

1.  **Seller Manages Products:** Each seller manages their products (`Item` doctype) and stock levels within their assigned `Warehouse`.
2.  **Customer Places Order:** A customer places an order. A `Sales Invoice` is created in the platform owner's company. The items on the invoice are linked to the seller's warehouse.
3.  **Payment Collection:** All payments (digital and cash) are collected by the platform owner.
4.  **Commission:** The platform owner calculates their commission on the sale.
5.  **Payout to Seller:** The platform owner pays out the net amount (Total Sale - Commission) to the seller.

### Key Requirements & Challenges

1.  **Data Segregation:** Since all transactions are in one company, we need a robust way to segregate data for each seller.
    -   All transactional doctypes (`Sales Invoice`, `Item`, etc.) will need a `Link` field to the `Seller` doctype.
    -   Permissions will need to be carefully configured so that a seller can only see and manage their own data (their items, their sales invoices, etc.).

2.  **Seller Dashboard & Reporting:**
    -   Sellers will need a dashboard that shows only their own sales, stock levels, and payouts.
    -   Standard Frappe reports will need to be filtered by seller, or custom reports will need to be created.

3.  **Payout Management:**
    -   A system is needed to track sales, calculate commissions, and manage the payout process to sellers.
    -   This will likely involve a custom "Seller Payout" doctype to record each payout transaction.

4.  **Accounting for Payouts:**
    -   The user has raised a valid concern about how sellers should record the payout in their own company's books.
    -   The payout is not a "sale". It is the settlement of funds owed. The seller's off-platform books would need to record this as cash received against a "Receivable from Platform" account. This is an accounting process that happens outside the scope of the platform's direct functionality for the seller. The platform's main responsibility is to provide the seller with the necessary reports to do their own accounting correctly.

### Implementation Strategy

This single-company model is simpler to implement initially than a multi-company model with inter-company transactions. The focus will be on:
1.  **Phase 1: Foundational Setup:** Create the `Seller` doctype and establish the data model for linking transactions to sellers.
2.  **Phase 2: Core Transaction Flow:** Enable the basic sales cycle and document the manual processes for payouts and commissions.
3.  **Phase 3: Automation and Reporting:** Automate the payout and commission calculations and build the seller-specific dashboards and reports.
