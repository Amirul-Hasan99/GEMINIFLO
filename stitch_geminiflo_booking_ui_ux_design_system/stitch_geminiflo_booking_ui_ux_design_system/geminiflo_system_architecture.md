# Geminiflo Booking - Architecture & Screen Plan

## User Roles & Architecture
1. **USER / PENYEWA**:
   - Home & Explore Dashboard (Greeting, Quick Actions, Featured Papan Bunga, Promotional Banner, Upcoming Booking Card, Bottom Nav)
   - Catalog & Availability Explorer (Filter by Category: Pernikahan, Duka Cita, Grand Opening, Wisuda; Live Status Badges: Available, Limited, Unavailable; Interactive Date Availability Sheet)
   - Product Detail & Date Booking Flow (Full gallery, dimension specs, real-time availability check, structured booking form with delivery address, event banner typography greeting text)
   - Manual Payment & Verification Timeline (Bank Transfer BCA/Mandiri, E-Wallet DANA/GoPay, QRIS preview, Upload payment proof modal, Two-Status Lifecycle Engine: Booking Status vs Payment Status, WhatsApp follow-up link)

2. **ADMIN / PENGELOLA**:
   - Admin Command Dashboard & Verification Center (Overview metrics: Total Orders, Pending Verification alert, Revenue, Booking Status Timeline, Quick Verification Queue)
   - Payment Verification & Booking Status Manager (Side-by-side payment proof viewer, reject with mandatory reason dialog, instant status transition to Verified -> Confirmed, WhatsApp direct link)
