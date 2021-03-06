﻿#ifdef _WINDOWS

#include "VideoPainter.h"

#define ID_TIMER_REPAINT 1
#define ID_TIMER_TIMEOUT 2

PainterBase::PainterBase(const std::string& params, int x, int y, int w, int h)
	: x(x), y(y), w(w), h(h)
{
	int trans = 0;
	JSON j = JSON::parse(params);
	{ auto it = j.find("color"); if (it != j.end()) color.SetFromCOLORREF(*it); }
	{ auto it = j.find("duration"); if (it != j.end()) duration = *it; }
	{ auto it = j.find("frameCount"); if (it != j.end()) limit = *it; }
	{ auto it = j.find("frameDelay"); if (it != j.end()) delay = *it; }
	{ auto it = j.find("thickness"); if (it != j.end()) thick = *it; }
	{ auto it = j.find("transparency"); if (it != j.end()) trans = *it; }
	if (trans) color = Color(trans & 0xFF, color.GetRed(), color.GetGreen(), color.GetBlue());
	if (limit <= 0) limit = 1;
	if (delay == 0 || step > limit) step = limit;
}

void RecanglePainter::draw(Graphics& graphics)
{
	int z = thick / 2;
	Pen pen(color, (REAL)thick);
	Point points[4] = {
		{z, z},
		{w - 2 * z, z},
		{w - 2 * z, h - 2 * z},
		{z, h - 2 * z},
	};
	graphics.DrawPolygon(&pen, points, 4);
}

ShadowPainter::ShadowPainter(const std::string& p, int x, int y, int w, int h)
	: PainterBase(p), X(x), Y(y), W(w), H(h)
{
	RECT rect;
	GetWindowRect(GetDesktopWindow(), &rect);
	X -= rect.left;
	Y -= rect.top;
	this->x = rect.left;
	this->y = rect.top;
	this->w = rect.left + rect.right;
	this->h = rect.bottom - rect.top;
	JSON j = JSON::parse(p);
	{ auto it = j.find("fontName"); if (it != j.end()) fontName = MB2WC(*it); }
	{ auto it = j.find("fontSize"); if (it != j.end()) fontSize = *it; }
	{ auto it = j.find("text"); if (it != j.end()) text = MB2WC(*it); }
}

void ShadowPainter::draw(Graphics& graphics)
{
	int xx, yy;
	REAL x1, x2, x3, y1, y2, y3;
	Region screen(Rect(0, 0, w, h));
	screen.Exclude(Rect(X, Y, W, H));
	SolidBrush brush(Color(color.GetAlpha(), 0, 0, 0));
	graphics.FillRegion(&brush, &screen);

	int ww = max(X, w - (X + W));
	int hh = max(Y, h - (Y + H));
	int d = 30;

	if (ww * h < hh * w) {
		xx = (2 * X + W > w) ? 0 : w / 2;
		yy = (2 * Y + H > h) ? 0 : Y + H;
		ww = w / 2;
		x1 = (REAL)X + (REAL)W / 2;
		y1 = REAL(yy ? yy + d : hh - d);
		pos = xx ? AP::L : AP::R;
	}
	else {
		xx = (2 * X + W > w) ? 0 : X + W;
		yy = (2 * Y + H > h) ? 0 : h / 2;
		hh = h / 2;
		y1 = (REAL)Y + REAL(H) / 2;
		x1 = REAL(xx ? xx + d : ww - d);
		pos = yy ? AP::T : AP::B;
	}

	SolidBrush textBrush(Color::White);
	FontFamily fontFamily(fontName.c_str());
	Font font(&fontFamily, fontSize, FontStyleRegular, UnitPoint);
	StringFormat format;
	format.SetAlignment(StringAlignment::StringAlignmentCenter);
	format.SetLineAlignment(StringAlignment::StringAlignmentCenter);
	RectF rect((REAL)xx, (REAL)yy, (REAL)ww, (REAL)hh), r;
	graphics.MeasureString((WCHAR*)text.c_str(), (int)text.size(), &font, rect, &format, &r);
	graphics.DrawString((WCHAR*)text.c_str(), (int)text.size(), &font, r, &format, &textBrush);

	switch (pos) {
	case AP::L: x3 = r.X; y3 = r.Y + r.Height / 2; x2 = x1; y2 = y3; break;
	case AP::R: x3 = r.X + r.Width; y3 = r.Y + r.Height / 2; x2 = x1; y2 = y3; break;
	case AP::T: x3 = r.X + r.Width / 2; y3 = r.Y; x2 = x3; y2 = y1; break;
	case AP::B: x3 = r.X + r.Width / 2; y3 = r.Y + r.Height; x2 = x3; y2 = y1; break;
	}

	Pen pen(Color::White, (REAL)thick);
	PointF points[] = { {(REAL)x1, (REAL)y1}, {x2, y2}, {x2, y2}, {x3, y3} };
	AdjustableArrowCap arrow(12, 12, false);
	pen.SetCustomStartCap(&arrow);
	graphics.DrawBeziers(&pen, points, 4);
}

void EllipsePainter::draw(Graphics& graphics)
{
	Pen pen(color, (REAL)thick);
	graphics.DrawEllipse(&pen, thick, thick, w - 2 * thick, h - 2 * thick);
}

BezierPainter::BezierPainter(const std::string& params, const std::string& text)
	: PainterBase(params)
{
	auto list = JSON::parse(text);
	for (size_t i = 0; i < list.size(); i++) {
		auto item = list[i];
		points.push_back({ item["x"], item["y"] });
	}
	if (list.size() == 0) throw 0;
	auto p = points[0];
	int left = p.X, top = p.Y, right = p.X, bottom = p.Y;
	for (auto it = points.begin() + 1; it != points.end(); ++it) {
		if (left > it->X) left = it->X;
		if (top > it->Y) top = it->Y;
		if (right < it->X) right = it->X;
		if (bottom < it->Y) bottom = it->Y;
	}
	x = left - 2 * thick;
	y = top - 2 * thick;
	w = right - left + 4 * thick;
	h = bottom - top + 4 * thick;
	for (auto it = points.begin(); it != points.end(); ++it) {
		it->X -= x;
		it->Y -= y;
	}
}

void BezierPainter::draw(Graphics& graphics)
{
	REAL z = (REAL)thick;
	Pen pen(color, z);
	AdjustableArrowCap arrow(8, 4);
	pen.SetStartCap(LineCapRoundAnchor);
	pen.SetCustomEndCap(&arrow);
	auto p = points;
	int X = p[0].X;
	int Y = p[0].Y;
	for (auto it = p.begin() + 1; it != p.end(); ++it) {
		it->X = X + (it->X - X) * step / limit;
		it->Y = Y + (it->Y - Y) * step / limit;
	}
	graphics.DrawBeziers(&pen, p.data(), (INT)p.size());
}

void ArrowPainter::draw(Graphics& graphics)
{
	REAL z = (REAL)thick;
	Pen pen(color, z);
	AdjustableArrowCap arrow(8, 4);
	pen.SetStartCap(LineCapRoundAnchor);
	pen.SetCustomEndCap(&arrow);
	int X1 = x1 - x;
	int Y1 = y1 - y;
	int X2 = X1 + (x2 - x1) * step / limit;
	int Y2 = Y1 + (y2 - y1) * step / limit;
	graphics.DrawLine(&pen, X1, Y1, X2, Y2);
}

LRESULT PainterBase::repaint(HWND hWnd)
{
	GgiPlusToken::Init();
	Bitmap bitmap(w, h, PixelFormat32bppARGB);
	Graphics graphics(&bitmap);
	graphics.Clear(Color::Transparent);
	graphics.SetCompositingQuality(CompositingQuality::CompositingQualityHighQuality);
	graphics.SetSmoothingMode(SmoothingMode::SmoothingModeAntiAlias);
	graphics.SetTextRenderingHint(TextRenderingHint::TextRenderingHintAntiAlias);
	draw(graphics);

	if (delay) {
		if (step >= limit)
			KillTimer(hWnd, ID_TIMER_REPAINT);
		else ++step;
	}

	//Инициализируем составляющие временного DC, в который будет отрисована маска
	auto hDC = GetDC(hWnd);
	auto hCDC = CreateCompatibleDC(hDC);

	LPVOID bits;
	BITMAPINFO bi = {};
	bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
	bi.bmiHeader.biBitCount = 32;
	bi.bmiHeader.biCompression = BI_RGB;
	bi.bmiHeader.biWidth = w;
	bi.bmiHeader.biHeight = h;
	bi.bmiHeader.biPlanes = 1;
	auto hBitmap = CreateDIBSection(hDC, &bi, DIB_RGB_COLORS, &bits, NULL, 0);
	if (!hBitmap) return -1;

	SelectObject(hCDC, hBitmap);
	//Создаем объект Graphics на основе контекста окна
	Graphics window(hCDC);
	//Рисуем маску на окне
	window.DrawImage(&bitmap, 0, 0, w, h);

	//В параметрах ULW определяем, что в качестве значения полупрозрачности будет использоваться
	//альфа-компонент пикселей исходного изображения
	BLENDFUNCTION bf = {};
	bf.AlphaFormat = AC_SRC_ALPHA;
	bf.BlendOp = AC_SRC_OVER;
	bf.SourceConstantAlpha = 255;

	//Применяем отрисованную маску с альфой к окну
	SIZE size = { w, h };
	POINT ptDst = { x, y };
	POINT ptSrc = { 0, 0 };
	UpdateLayeredWindow(hWnd, hDC, &ptDst, &size, hCDC, &ptSrc, 0, &bf, ULW_ALPHA);

	DeleteObject(hBitmap);
	DeleteDC(hCDC);
	ReleaseDC(hWnd, hDC);
	return 0;
}

static LRESULT CALLBACK PainterWndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
	switch (message)
	{
	case WM_NCCREATE: {
		LPCREATESTRUCT lpcp = (LPCREATESTRUCT)lParam;
		lpcp->style &= (~WS_CAPTION);
		lpcp->style &= (~WS_BORDER);
		SetWindowLong(hWnd, GWL_STYLE, lpcp->style);
		return TRUE;
	}
	case WM_CREATE:
		return ((PainterBase*)((CREATESTRUCT*)lParam)->lpCreateParams)->repaint(hWnd);
	case WM_TIMER:
		switch (wParam) {
		case ID_TIMER_REPAINT:
			((PainterBase*)GetWindowLongPtr(hWnd, GWLP_USERDATA))->repaint(hWnd);
			break;
		case ID_TIMER_TIMEOUT:
			KillTimer(hWnd, ID_TIMER_REPAINT);
			KillTimer(hWnd, ID_TIMER_TIMEOUT);
			SendMessage(hWnd, WM_DESTROY, 0, 0);
			break;
		}
		return 0;
	case WM_DESTROY:
		PostQuitMessage(0);
		return 0;
	default:
		return DefWindowProc(hWnd, message, wParam, lParam);
	}
}

void PainterBase::create()
{
	LPCWSTR name = L"VanessaVideoPainter";
	WNDCLASS wndClass = {};
	wndClass.lpfnWndProc = PainterWndProc;
	wndClass.hInstance = hModule;
	wndClass.hCursor = LoadCursor(NULL, IDC_ARROW);
	wndClass.hbrBackground = (HBRUSH)GetStockObject(BLACK_BRUSH);
	wndClass.lpszClassName = name;
	RegisterClass(&wndClass);

	DWORD dwExStyle = WS_EX_LAYERED | WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_TRANSPARENT;
	HWND hWnd = CreateWindowEx(dwExStyle, name, name, WS_POPUP, x, y, w, h, NULL, NULL, hModule, this);
	SetWindowLongPtr(hWnd, GWLP_USERDATA, (LONG_PTR)this);
	if (delay) SetTimer(hWnd, ID_TIMER_REPAINT, delay, NULL);
	SetTimer(hWnd, ID_TIMER_TIMEOUT, duration, NULL);
	ShowWindow(hWnd, SW_SHOWNOACTIVATE);
	UpdateWindow(hWnd);
}

static DWORD WINAPI PainterThreadProc(LPVOID lpParam)
{
	std::unique_ptr<PainterBase> painter((PainterBase*)lpParam);
	painter->create();
	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}
	return 0;
}

void PainterBase::run()
{
	CreateThread(0, NULL, PainterThreadProc, (LPVOID)this, NULL, NULL);
}

#endif //_WINDOWS