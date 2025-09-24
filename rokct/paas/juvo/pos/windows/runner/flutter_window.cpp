#include "flutter_window.h"

#include <optional>

#include "flutter/generated_plugin_registrant.h"

// Add these includes for Windows APIs and macros
#include <windows.h>
#include <dwmapi.h>
#include <windowsx.h>

// Link with dwmapi.lib
#pragma comment(lib, "dwmapi.lib")

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
        : project_(project), dragging_(false), dragOffset_({0, 0}) {}

FlutterWindow::~FlutterWindow() {
    // Restore default power settings when the window is destroyed
    SetThreadExecutionState(ES_CONTINUOUS);
}

bool FlutterWindow::OnCreate() {
    if (!Win32Window::OnCreate()) {
        return false;
    }

    RECT frame = GetClientArea();

    flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
            frame.right - frame.left, frame.bottom - frame.top, project_);
    if (!flutter_controller_->engine() || !flutter_controller_->view()) {
        return false;
    }
    RegisterPlugins(flutter_controller_->engine());
    SetChildContent(flutter_controller_->view()->GetNativeWindow());

    ModifyWindowStyle();

    // Prevent the system from sleeping or turning off the display
    SetThreadExecutionState(ES_CONTINUOUS | ES_SYSTEM_REQUIRED | ES_DISPLAY_REQUIRED);

    return true;
}

void FlutterWindow::ModifyWindowStyle() {
    HWND hwnd = GetHandle();
    LONG style = GetWindowLong(hwnd, GWL_STYLE);
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_SYSMENU);
    style |= WS_MINIMIZEBOX | WS_MAXIMIZEBOX; // Allow minimize and maximize
    SetWindowLong(hwnd, GWL_STYLE, style);

    // Enable non-client area painting for custom drag handling
    DWMNCRENDERINGPOLICY ncrp = DWMNCRP_ENABLED;
    DwmSetWindowAttribute(hwnd, DWMWA_NCRENDERING_POLICY, &ncrp, sizeof(ncrp));

    // Extend the frame into the client area
    MARGINS margins = {0};
    DwmExtendFrameIntoClientArea(hwnd, &margins);

    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER);

    // Set the window background color to black
    HBRUSH hBrush = CreateSolidBrush(RGB(0, 0, 0));
    SetClassLongPtr(hwnd, GCLP_HBRBACKGROUND, (LONG_PTR)hBrush);

    // Redraw frame
    SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
                 SWP_FRAMECHANGED | SWP_NOMOVE | SWP_NOSIZE | SWP_NOZORDER | SWP_NOOWNERZORDER);
}

void FlutterWindow::OnDestroy() {
    if (flutter_controller_) {
        flutter_controller_ = nullptr;
    }

    // Restore default power settings
    SetThreadExecutionState(ES_CONTINUOUS);

    // Delete the brush we created
    HBRUSH hBrush = (HBRUSH)GetClassLongPtr(GetHandle(), GCLP_HBRBACKGROUND);
    DeleteObject(hBrush);

    Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
if (flutter_controller_) {
std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam, lparam);
if (result) {
return *result;
}
}

switch (message) {
case WM_NCCALCSIZE: {
if (wparam == TRUE) {
// Prevent Windows from adding a title bar or resizing border
return 0;
}
break;
}
case WM_NCHITTEST: {
POINT pt = { GET_X_LPARAM(lparam), GET_Y_LPARAM(lparam) };
ScreenToClient(hwnd, &pt);

// Consider the top 32 pixels of the window as the draggable area
if (pt.y < 32) {
if (IsZoomed(hwnd)) {
return HTMAXBUTTON;  // This will trigger WM_NCLBUTTONDOWN
}
return HTCAPTION;
}
break;
}
case WM_NCLBUTTONDOWN: {
if (wparam == HTMAXBUTTON && IsZoomed(hwnd)) {
dragging_ = true;
// Get the cursor position
POINT pt;
GetCursorPos(&pt);
// Calculate the restoration point (top-left corner of the window)
RECT rect;
GetWindowRect(hwnd, &rect);
int width = rect.right - rect.left;
int left = pt.x - (width / 2);
int top = pt.y;
// Restore the window
ShowWindow(hwnd, SW_RESTORE);
// Move the window to the new position
SetWindowPos(hwnd, nullptr, left, top, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
// Set drag offset
dragOffset_.x = pt.x - left;
dragOffset_.y = pt.y - top;
// Capture the mouse
SetCapture(hwnd);
return 0;
}
break;
}
case WM_MOUSEMOVE: {
if (dragging_) {
POINT pt;
GetCursorPos(&pt);
// Move the window
SetWindowPos(hwnd, nullptr, pt.x - dragOffset_.x, pt.y - dragOffset_.y, 0, 0, SWP_NOSIZE | SWP_NOZORDER);
}
break;
}
case WM_LBUTTONUP: {
if (dragging_) {
dragging_ = false;
ReleaseCapture();
}
break;
}
case WM_GETMINMAXINFO: {
MINMAXINFO* mmi = (MINMAXINFO*)lparam;
HMONITOR hmon = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
MONITORINFO mi = { sizeof(mi) };
if (GetMonitorInfo(hmon, &mi)) {
mmi->ptMaxPosition.x = mi.rcWork.left;
mmi->ptMaxPosition.y = mi.rcWork.top;
mmi->ptMaxSize.x = mi.rcWork.right - mi.rcWork.left;
mmi->ptMaxSize.y = mi.rcWork.bottom - mi.rcWork.top;
}
return 0;
}
case WM_SYSCOMMAND: {
if ((wparam & 0xFFF0) == SC_MINIMIZE || (wparam & 0xFFF0) == SC_MAXIMIZE || (wparam & 0xFFF0) == SC_RESTORE) {
DefWindowProc(hwnd, message, wparam, lparam);
ModifyWindowStyle();
return 0;
}
break;
}
}

return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
