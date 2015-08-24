--[[
	Copyright (c) 2014, Christoph "Youka" Spanknebel

	Permission is hereby granted, free of charge, to any person obtaining a copy
	of this software and associated documentation files (the "Software"), to deal
	in the Software without restriction, including without limitation the rights
	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
	copies of the Software, and to permit persons to whom the Software is
	furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
	THE SOFTWARE.
	-----------------------------------------------------------------------------------------------------------------
	Version: 2nd August 2014, 06:50 (GMT+1)
	
	Yutils
		table
			append(dst_t, src_t) -> table
			copy(t) -> table
			tostring(t) -> string
		utf8
			charrange(s, i) -> number
			chars(s) -> function
			len(s) -> number
		math
			arc_curve(x, y, cx, cy, angle) -> 8, 16, 24 or 32 numbers
			bezier(pct, pts) -> number, number, number
			create_matrix() -> table
				get_data() -> table
				set_data(matrix) -> table
				identity() -> table
				multiply(matrix2) -> table
				translate(x, y, z) -> table
				scale(x, y, z) -> table
				rotate(axis, angle) -> table
				inverse() -> [table]
				transform(x, y, z[, w]) -> number, number, number, number
			degree(x1, y1, z1, x2, y2, z2) -> number
			distance(x, y[, z]) -> number
			ortho(x1, y1, z1, x2, y2, z2) -> number, number, number
			randomsteps(min, max, step) -> number
			round(x) -> number
			stretch(x, y, z, length) -> number, number, number
			trim(x, min, max) -> number
		algorithm
			frames(starts, ends, dur) -> function
			lines(text) -> function
		shape
			bounding(shape) -> number, number, number, number
			detect(width, height, data[, compare_func]) -> table
			filter(shape, filter) -> string
			flatten(shape) -> string
			glue(src_shape, dst_shape[, transform_callback]) -> string
			move(shape, x, y) -> string
			split(shape, max_len) -> string
			to_outline(shape, width_xy[, width_y]) -> string
			to_pixels(shape) -> table
			transform(shape, matrix) -> string
		decode
			create_bmp_reader(filename) -> table
				file_size() -> number
				width() -> number
				height() -> number
				bit_depth() -> number
				data_size() -> number
				row_size() -> number
				data_raw() -> string
				data_packed() -> table
				data_text() -> string
			create_font(font, bold, italic, underline, strikeout, size[, xscale, yscale, hspace]) -> table
				metrics() -> table
				text_extents(text) -> table
				text_to_shape(text) -> string
			list_fonts([with_filenames]) -> table
]]

-- Configuration
local FP_PRECISION = 100	-- Floating point precision by divisor (for shape points)
local CURVE_TOLERANCE = 1	-- Angle in degree to define a curve as flat
local MAX_CIRCUMFERENCE = 1.5	-- Circumference step size to create round edges out of lines
local SUPERSAMPLING = 8	-- Anti-aliasing precision for shape to pixels conversion
local FONT_PRECISION = 64	-- Font scale for better precision output from native font system
local LIBASS_FONTHACK = false	-- Scale font data to fontsize (no effect on windows)

-- Load FFI interface
local ffi = require("ffi")
-- Check OS & load fitting system libraries
local advapi, pangocairo, fontconfig
if ffi.os == "Windows" then
	-- WinGDI already loaded in C namespace by default
	-- Load advanced winapi library
	advapi = ffi.load("Advapi32.dll")
	-- Set C definitions for WinAPI
	ffi.cdef([[
enum{CP_UTF8 = 65001};
enum{MM_TEXT = 1};
enum{TRANSPARENT = 1};
enum{
	FW_NORMAL = 400,
	FW_BOLD = 700
};
enum{DEFAULT_CHARSET = 1};
enum{OUT_TT_PRECIS = 4};
enum{CLIP_DEFAULT_PRECIS = 0};
enum{ANTIALIASED_QUALITY = 4};
enum{DEFAULT_PITCH = 0x0};
enum{FF_DONTCARE = 0x0};
enum{
	PT_MOVETO = 0x6,
	PT_LINETO = 0x2,
	PT_BEZIERTO = 0x4,
	PT_CLOSEFIGURE = 0x1
};
typedef unsigned int UINT;
typedef unsigned long DWORD;
typedef DWORD* LPDWORD;
typedef const char* LPCSTR;
typedef const wchar_t* LPCWSTR;
typedef wchar_t* LPWSTR;
typedef char* LPSTR;
typedef void* HANDLE;
typedef HANDLE HDC;
typedef int BOOL;
typedef BOOL* LPBOOL;
typedef unsigned int size_t;
typedef HANDLE HFONT;
typedef HANDLE HGDIOBJ;
typedef long LONG;
typedef wchar_t WCHAR;
typedef unsigned char BYTE;
typedef BYTE* LPBYTE;
typedef int INT;
typedef long LPARAM;
static const int LF_FACESIZE = 32;
static const int LF_FULLFACESIZE = 64;
typedef struct{
	LONG tmHeight;
	LONG tmAscent;
	LONG tmDescent;
	LONG tmInternalLeading;
	LONG tmExternalLeading;
	LONG tmAveCharWidth;
	LONG tmMaxCharWidth;
	LONG tmWeight;
	LONG tmOverhang;
	LONG tmDigitizedAspectX;
	LONG tmDigitizedAspectY;
	WCHAR tmFirstChar;
	WCHAR tmLastChar;
	WCHAR tmDefaultChar;
	WCHAR tmBreakChar;
	BYTE tmItalic;
	BYTE tmUnderlined;
	BYTE tmStruckOut;
	BYTE tmPitchAndFamily;
	BYTE tmCharSet;
}TEXTMETRICW, *LPTEXTMETRICW;
typedef struct{
	LONG cx;
	LONG cy;
}SIZE, *LPSIZE;
typedef struct{
	LONG left;
	LONG top;
	LONG right;
	LONG bottom;
}RECT;
typedef const RECT* LPCRECT;
typedef struct{
	LONG x;
	LONG y;
}POINT, *LPPOINT;
typedef struct{
  LONG  lfHeight;
  LONG  lfWidth;
  LONG  lfEscapement;
  LONG  lfOrientation;
  LONG  lfWeight;
  BYTE  lfItalic;
  BYTE  lfUnderline;
  BYTE  lfStrikeOut;
  BYTE  lfCharSet;
  BYTE  lfOutPrecision;
  BYTE  lfClipPrecision;
  BYTE  lfQuality;
  BYTE  lfPitchAndFamily;
  WCHAR lfFaceName[LF_FACESIZE];
}LOGFONTW, *LPLOGFONTW;
typedef struct{
  LOGFONTW elfLogFont;
  WCHAR   elfFullName[LF_FULLFACESIZE];
  WCHAR   elfStyle[LF_FACESIZE];
  WCHAR   elfScript[LF_FACESIZE];
}ENUMLOGFONTEXW, *LPENUMLOGFONTEXW;
enum{
	FONTTYPE_RASTER = 1,
	FONTTYPE_DEVICE = 2,
	FONTTYPE_TRUETYPE = 4
};
typedef int (__stdcall *FONTENUMPROC)(const ENUMLOGFONTEXW*, const void*, DWORD, LPARAM);
enum{ERROR_SUCCESS = 0};
typedef HANDLE HKEY;
typedef HKEY* PHKEY;
enum{HKEY_LOCAL_MACHINE = 0x80000002};
typedef enum{KEY_READ = 0x20019}REGSAM;

int MultiByteToWideChar(UINT, DWORD, LPCSTR, int, LPWSTR, int);
int WideCharToMultiByte(UINT, DWORD, LPCWSTR, int, LPSTR, int, LPCSTR, LPBOOL);
HDC CreateCompatibleDC(HDC);
BOOL DeleteDC(HDC);
int SetMapMode(HDC, int);
int SetBkMode(HDC, int);
size_t wcslen(const wchar_t*);
HFONT CreateFontW(int, int, int, int, int, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, DWORD, LPCWSTR);
HGDIOBJ SelectObject(HDC, HGDIOBJ);
BOOL DeleteObject(HGDIOBJ);
BOOL GetTextMetricsW(HDC, LPTEXTMETRICW);
BOOL GetTextExtentPoint32W(HDC, LPCWSTR, int, LPSIZE);
BOOL BeginPath(HDC);
BOOL ExtTextOutW(HDC, int, int, UINT, LPCRECT, LPCWSTR, UINT, const INT*);
BOOL EndPath(HDC);
int GetPath(HDC, LPPOINT, LPBYTE, int);
BOOL AbortPath(HDC);
int EnumFontFamiliesExW(HDC, LPLOGFONTW, FONTENUMPROC, LPARAM, DWORD);
LONG RegOpenKeyExA(HKEY, LPCSTR, DWORD, REGSAM, PHKEY);
LONG RegCloseKey(HKEY);
LONG RegEnumValueW(HKEY, DWORD, LPWSTR, LPDWORD, LPDWORD, LPDWORD, LPBYTE, LPDWORD);
	]])
else	-- Unix
	-- Load pangocairo library
	pangocairo = ffi.load("libpangocairo-1.0.so")
	-- Load fontconfig library
	fontconfig = ffi.load("libfontconfig.so")
	-- Set C definitions for Pangocairo
	ffi.cdef([[
typedef enum{
    CAIRO_FORMAT_INVALID   = -1,
    CAIRO_FORMAT_ARGB32    = 0,
    CAIRO_FORMAT_RGB24     = 1,
    CAIRO_FORMAT_A8        = 2,
    CAIRO_FORMAT_A1        = 3,
    CAIRO_FORMAT_RGB16_565 = 4,
    CAIRO_FORMAT_RGB30     = 5
}cairo_format_t;
typedef void cairo_surface_t;
typedef void cairo_t;
typedef void PangoLayout;
typedef void* gpointer;
static const int PANGO_SCALE = 1024;
typedef void PangoFontDescription;
typedef enum{
	PANGO_WEIGHT_THIN	= 100,
	PANGO_WEIGHT_ULTRALIGHT = 200,
	PANGO_WEIGHT_LIGHT = 300,
	PANGO_WEIGHT_NORMAL = 400,
	PANGO_WEIGHT_MEDIUM = 500,
	PANGO_WEIGHT_SEMIBOLD = 600,
	PANGO_WEIGHT_BOLD = 700,
	PANGO_WEIGHT_ULTRABOLD = 800,
	PANGO_WEIGHT_HEAVY = 900,
	PANGO_WEIGHT_ULTRAHEAVY = 1000
}PangoWeight;
typedef enum{
	PANGO_STYLE_NORMAL,
	PANGO_STYLE_OBLIQUE,
	PANGO_STYLE_ITALIC
}PangoStyle;
typedef void PangoAttrList;
typedef void PangoAttribute;
typedef enum{
	PANGO_UNDERLINE_NONE,
	PANGO_UNDERLINE_SINGLE,
	PANGO_UNDERLINE_DOUBLE,
	PANGO_UNDERLINE_LOW,
	PANGO_UNDERLINE_ERROR
}PangoUnderline;
typedef int gint;
typedef gint gboolean;
typedef void PangoContext;
typedef unsigned int guint;
typedef struct{
	guint ref_count;
	int ascent;
	int descent;
	int approximate_char_width;
	int approximate_digit_width;
	int underline_position;
	int underline_thickness;
	int strikethrough_position;
	int strikethrough_thickness;
}PangoFontMetrics;
typedef void PangoLanguage;
typedef struct{
	int x;
	int y;
	int width;
	int height;
}PangoRectangle;
typedef enum{
	CAIRO_STATUS_SUCCESS = 0
}cairo_status_t;
typedef enum{
	CAIRO_PATH_MOVE_TO,
	CAIRO_PATH_LINE_TO,
	CAIRO_PATH_CURVE_TO,
	CAIRO_PATH_CLOSE_PATH
}cairo_path_data_type_t;
typedef union{
	struct{
		cairo_path_data_type_t type;
		int length;
	}header;
	struct{
		double x, y;
	}point;
}cairo_path_data_t;
typedef struct{
	cairo_status_t status;
	cairo_path_data_t* data;
	int num_data;
}cairo_path_t;
typedef void FcConfig;
typedef void FcPattern;
typedef struct{
	int nobject;
	int sobject;
	const char** objects;
}FcObjectSet;
typedef struct{
	int nfont;
	int sfont;
	FcPattern** fonts;
}FcFontSet;
typedef enum{
	FcResultMatch,
	FcResultNoMatch,
	FcResultTypeMismatch,
	FcResultNoId,
	FcResultOutOfMemory
}FcResult;
typedef unsigned char FcChar8;
typedef int FcBool;

cairo_surface_t* cairo_image_surface_create(cairo_format_t, int, int);
void cairo_surface_destroy(cairo_surface_t*);
cairo_t* cairo_create(cairo_surface_t*);
void cairo_destroy(cairo_t*);
PangoLayout* pango_cairo_create_layout(cairo_t*);
void g_object_unref(gpointer);
PangoFontDescription* pango_font_description_new(void);
void pango_font_description_free(PangoFontDescription*);
void pango_font_description_set_family(PangoFontDescription*, const char*);
void pango_font_description_set_weight(PangoFontDescription*, PangoWeight);
void pango_font_description_set_style(PangoFontDescription*, PangoStyle);
void pango_font_description_set_absolute_size(PangoFontDescription*, double);
void pango_layout_set_font_description(PangoLayout*, PangoFontDescription*);
PangoAttrList* pango_attr_list_new(void);
void pango_attr_list_unref(PangoAttrList*);
void pango_attr_list_insert(PangoAttrList*, PangoAttribute*);
PangoAttribute* pango_attr_underline_new(PangoUnderline);
PangoAttribute* pango_attr_strikethrough_new(gboolean);
PangoAttribute* pango_attr_letter_spacing_new(int);
void pango_layout_set_attributes(PangoLayout*, PangoAttrList*);
PangoContext* pango_layout_get_context(PangoLayout*);
const PangoFontDescription* pango_layout_get_font_description(PangoLayout*);
PangoFontMetrics* pango_context_get_metrics(PangoContext*, const PangoFontDescription*, PangoLanguage*);
void pango_font_metrics_unref(PangoFontMetrics*);
int pango_font_metrics_get_ascent(PangoFontMetrics*);
int pango_font_metrics_get_descent(PangoFontMetrics*);
int pango_layout_get_spacing(PangoLayout*);
void pango_layout_set_text(PangoLayout*, const char*, int);
void pango_layout_get_pixel_extents(PangoLayout*, PangoRectangle*, PangoRectangle*);
void cairo_save(cairo_t*);
void cairo_restore(cairo_t*);
void cairo_scale(cairo_t*, double, double);
void pango_cairo_layout_path(cairo_t*, PangoLayout*);
void cairo_new_path(cairo_t*);
cairo_path_t* cairo_copy_path(cairo_t*);
void cairo_path_destroy(cairo_path_t*);
FcConfig* FcInitLoadConfigAndFonts(void);
FcPattern* FcPatternCreate(void);
void FcPatternDestroy(FcPattern*);
FcObjectSet* FcObjectSetBuild(const char*, ...);
void FcObjectSetDestroy(FcObjectSet*);
FcFontSet* FcFontList(FcConfig*, FcPattern*, FcObjectSet*);
void FcFontSetDestroy(FcFontSet*);
FcResult FcPatternGetString(FcPattern*, const char*, int, FcChar8**);
FcResult FcPatternGetBool(FcPattern*, const char*, int, FcBool*);
	]])
end

-- Helper functions
local function roundf(x)
	return math.floor(x * FP_PRECISION) / FP_PRECISION
end
local function rotate2d(x, y, angle)
	local ra = math.rad(angle)
	return math.cos(ra)*x - math.sin(ra)*y,
		math.sin(ra)*x + math.cos(ra)*y
end
local function utf8_to_utf16(s)
	-- Get resulting utf16 characters number (+ null-termination)
	local wlen = ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, s, -1, nil, 0)
	-- Allocate array for utf16 characters storage
	local ws = ffi.new("wchar_t[?]", wlen)
	-- Convert utf8 string to utf16 characters
	ffi.C.MultiByteToWideChar(ffi.C.CP_UTF8, 0x0, s, -1, ws, wlen)
	-- Return utf16 C string
	return ws
end
local function utf16_to_utf8(ws)
	-- Get resulting utf8 characters number (+ null-termination)
	local slen = ffi.C.WideCharToMultiByte(ffi.C.CP_UTF8, 0x0, ws, -1, nil, 0, nil, nil)
	-- Allocate array for utf8 characters storage
	local s = ffi.new("char[?]", slen)
	-- Convert utf16 string to utf8 characters
	ffi.C.WideCharToMultiByte(ffi.C.CP_UTF8, 0x0, ws, -1, s, slen, nil, nil)
	-- Return utf8 Lua string
	return ffi.string(s)
end

-- Create library table
local Yutils
Yutils = {
	-- Table sublibrary
	table = {
		-- Appends table to table
		append = function(dst_t, src_t)
			-- Check arguments
			if type(dst_t) ~= "table" or type(src_t) ~= "table" then
				error("2 tables expected", 2)
			end
			-- Insert source table array elements to the end of destination table
			local dst_t_n = #dst_t
			for i, v in ipairs(src_t) do
				dst_t_n = dst_t_n + 1
				dst_t[dst_t_n] = v
			end
			-- Return (modified) destination table
			return dst_t
		end,
		-- Copies table deep
		copy = function(t)
			-- Check argument
			if type(t) ~= "table" then
				error("table expected", 2)
			end
			-- Copy & return
			local function copy_recursive(old_t)
				local new_t = {}
				for key, value in pairs(old_t) do
					new_t[key] = type(value) == "table" and copy_recursive(value) or value
				end
				return new_t
			end
			return copy_recursive(t)
		end,
		-- Converts table to string
		tostring = function(t)
			-- Check argument
			if type(t) ~= "table" then
				error("table expected", 2)
			end
			-- Result storage
			local result, result_n = {}, 0
			-- Convert to string!
			local function convert_recursive(t, space)
				for key, value in pairs(t) do
					if type(key) == "string" then
						key = string.format("%q", key)
					end
					if type(value) == "string" then
						value = string.format("%q", value)
					end
					result_n = result_n + 1
					result[result_n] = string.format("%s[%s] = %s", space, tostring(key), tostring(value))
					if type(value) == "table" then
						convert_recursive(value, space .. "\t")
					end
				end
			end
			convert_recursive(t, "")
			-- Return result as string
			return table.concat(result, "\n")
		end
	},
	-- UTF8 sublibrary
	utf8 = {
--[[
		UTF16 -> UTF8
		--------------
		U-00000000 - U-0000007F:		0xxxxxxx
		U-00000080 - U-000007FF:		110xxxxx 10xxxxxx
		U-00000800 - U-0000FFFF:		1110xxxx 10xxxxxx 10xxxxxx
		U-00010000 - U-001FFFFF:		11110xxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-00200000 - U-03FFFFFF:		111110xx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
		U-04000000 - U-7FFFFFFF:		1111110x 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx 10xxxxxx
]]
		-- UTF8 character range at string codepoint
		charrange = function(s, i)
			-- Check arguments
			if type(s) ~= "string" or type(i) ~= "number" or i < 1 or i > #s then
				error("string and string index expected", 2)
			end
			-- Evaluate codepoint to range
			local byte = s:byte(i)
			return not byte and 0 or
					byte < 192 and 1 or
					byte < 224 and 2 or
					byte < 240 and 3 or
					byte < 248 and 4 or
					byte < 252 and 5 or
					6
		end,
		-- Creates iterator through UTF8 characters
		chars = function(s)
			-- Check argument
			if type(s) ~= "string" then
				error("string expected", 2)
			end
			-- Return utf8 characters iterator
			local char_i, s_pos, s_len = 0, 1, #s
			return function()
				if s_pos > s_len then
					return
				else
					char_i = char_i + 1
					local cur_pos = s_pos
					s_pos = s_pos + Yutils.utf8.charrange(s, s_pos)
					return char_i, s:sub(cur_pos, s_pos-1)
				end
			end
		end,
		-- Get UTF8 characters number in string
		len = function(s)
			-- Check argument
			if type(s) ~= "string" then
				error("string expected", 2)
			end
			-- Count UTF8 characters
			local n = 0
			for _ in Yutils.utf8.chars(s) do
				n = n + 1
			end
			return n
		end
	},
	-- Math sublibrary
	math = {
		-- Converts an arc to 1-4 cubic bezier curve(s)
		arc_curve = function(x, y, cx, cy, angle)
			-- Check arguments
			if type(x) ~= "number" or type(y) ~= "number" or type(cx) ~= "number" or type(cy) ~= "number" or type(angle) ~= "number" or
				angle < -360 or angle > 360 then
				error("start & center point and valid angle (-360<=x<=360) expected", 2)
			end
			-- Something to do?
			if angle ~= 0 then
				-- Factor for bezier control points distance to node points
				local kappa = 4 * (math.sqrt(2) - 1) / 3
				-- Relative points to center
				local rx0, ry0, rx1, ry1, rx2, ry2, rx3, ry3, rx03, ry03 = x - cx, y - cy
				-- Define arc clock direction & set angle to positive range
				local cw = angle > 0 and 1 or -1
				if angle < 0 then
					angle = -angle
				end
				-- Create curves in 90 degree chunks
				local curves, curves_n, angle_sum, cur_angle_pct = {}, 0, 0
				repeat
					-- Get arc end point
					cur_angle_pct = math.min(angle - angle_sum, 90) / 90
					rx3, ry3 = rotate2d(rx0, ry0, cw * 90 * cur_angle_pct)
					-- Get arc start to end vector
					rx03, ry03 = rx3 - rx0, ry3 - ry0
					-- Scale arc vector to curve node <-> control point distance
					rx03, ry03 = Yutils.math.stretch(rx03, ry03, 0, math.sqrt(Yutils.math.distance(rx03, ry03)^2/2) * kappa)
					-- Get curve control points
					rx1, ry1 = rotate2d(rx03, ry03, cw * -45 * cur_angle_pct)
					rx1, ry1 = rx0 + rx1, ry0 + ry1
					rx2, ry2 = rotate2d(-rx03, -ry03, cw * 45 * cur_angle_pct)
					rx2, ry2 = rx3 + rx2, ry3 + ry2
					-- Insert curve to output
					curves[curves_n+1], curves[curves_n+2], curves[curves_n+3], curves[curves_n+4],
					curves[curves_n+5], curves[curves_n+6], curves[curves_n+7], curves[curves_n+8] =
					cx + rx0, cy + ry0, cx + rx1, cy + ry1, cx + rx2, cy + ry2, cx + rx3, cy + ry3
					curves_n = curves_n + 8
					-- Prepare next curve
					rx0, ry0 = rx3, ry3
					angle_sum = angle_sum + 90
				until angle_sum >= angle
				-- Return curve points as tuple
				if unpack then
					return unpack(curves)
				else
					return table.unpack(curves)
				end
			end
		end,
		-- Get point on n-degree bezier curve
		bezier = function(pct, pts)
			-- Check arguments
			if type(pct) ~= "number" or type(pts) ~= "table" or pct < 0 or pct > 1 then
				error("percent number and points table expected", 2)
			end
			for _, value in ipairs(pts) do
				if type(value[1]) ~= "number" or type(value[2]) ~= "number" or (value[3] ~= nil and type(value[3]) ~= "number") then
					error("points have to be tables with 2 or 3 numbers", 2)
				end
			end
			--Factorial
			local function fac(n)
				local k = 1
				if n > 1 then
					for i=2, n do
						k = k * i
					end
				end
				return k
			end
			--Binomial coefficient
			local function bin(i, n)
				return fac(n) / (fac(i) * fac(n-i))
			end
			--Bernstein polynom
			local function bernstein(pct, i, n)
				return bin(i, n) * pct^i * (1 - pct)^(n - i)
			end
			--Calculate coordinate
			local ret_x, ret_y, ret_z = 0, 0, 0
			local n, bern, pt = #pts - 1
			for i=0, n do
				bern = bernstein(pct, i, n)
				pt = pts[i+1]
				ret_x = ret_x + pt[1] * bern
				ret_y = ret_y + pt[2] * bern
				ret_z = ret_z + (pt[3] or 0) * bern
			end
			return ret_x, ret_y, ret_z
		end,
		-- Creates 3d matrix
		create_matrix = function()
			-- Matrix data
			local matrix = {1, 0, 0, 0,
								0, 1, 0, 0,
								0, 0, 1, 0,
								0, 0, 0, 1}
			-- Matrix object
			local obj
			obj = {
				-- Get matrix data
				get_data = function()
					return Yutils.table.copy(matrix)
				end,
				-- Set matrix data
				set_data = function(new_matrix)
					-- Check arguments
					if type(new_matrix) ~= "table" or #new_matrix ~= 16 then
						error("4x4 matrix expected", 2)
					end
					for _, value in ipairs(new_matrix) do
						if type(value) ~= "number" then
							error("matrix must contain only numbers", 2)
						end
					end
					-- Replace old matrix
					matrix = Yutils.table.copy(new_matrix)
				end,
				-- Set matrix to identity
				identity = function()
					-- Set matrix to default / no transformation
					matrix[1] = 1
					matrix[2] = 0
					matrix[3] = 0
					matrix[4] = 0
					matrix[5] = 0
					matrix[6] = 1
					matrix[7] = 0
					matrix[8] = 0
					matrix[9] = 0
					matrix[10] = 0
					matrix[11] = 1
					matrix[12] = 0
					matrix[13] = 0
					matrix[14] = 0
					matrix[15] = 0
					matrix[16] = 1
					-- Return this object
					return obj
				end,
				-- Multiplies matrix with given one
				multiply = function(matrix2)
					-- Check arguments
					if type(matrix2) ~= "table" or #matrix2 ~= 16 then
						error("4x4 matrix expected", 2)
					end
					for _, value in ipairs(matrix2) do
						if type(value) ~= "number" then
							error("matrix must contain only numbers", 2)
						end
					end
					-- Multipy matrices to create new one
					local new_matrix = {0, 0, 0, 0,
												0, 0, 0, 0,
												0, 0, 0, 0,
												0, 0, 0, 0}
					for i=1, 16 do
						for j=0, 3 do
							new_matrix[i] = new_matrix[i] + matrix[1 + (i-1) % 4 + j * 4] * matrix2[1 + math.floor((i-1) / 4) * 4 + j]
						end
					end
					-- Replace old matrix with multiply result
					matrix = new_matrix
					-- Return this object
					return obj
				end,
				-- Applies translation to matrix
				translate = function(x, y, z)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
						error("3 translation values expected", 2)
					end
					-- Add translation to matrix
					obj.multiply({1, 0, 0, 0,
									0, 1, 0, 0,
									0, 0, 1, 0,
									x, y, z, 1})
					-- Return this object
					return obj
				end,
				-- Applies scale to matrix
				scale = function(x, y, z)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" then
						error("3 scale factors expected", 2)
					end
					-- Add scale to matrix
					obj.multiply({x, 0, 0, 0,
									0, y, 0, 0,
									0, 0, z, 0,
									0, 0, 0, 1})
					-- Return this object
					return obj
				end,
				-- Applies rotation to matrix
				rotate = function(axis, angle)
					-- Check arguments
					if (axis ~= "x" and axis ~= "y" and axis ~= "z") or type(angle) ~= "number" then
						error("axis (as string) and angle (in degree) expected", 2)
					end
					-- Convert angle from degree to radian
					angle = math.rad(angle)
					-- Rotate by axis
					if axis == "x" then
						obj.multiply({1, 0, 0, 0,
									0, math.cos(angle), -math.sin(angle), 0,
									0, math.sin(angle), math.cos(angle), 0,
									0, 0, 0, 1})
					elseif axis == "y" then
						obj.multiply({math.cos(angle), 0, math.sin(angle), 0,
									0, 1, 0, 0,
									-math.sin(angle), 0, math.cos(angle), 0,
									0, 0, 0, 1})
					else	-- axis == "z"
						obj.multiply({math.cos(angle), -math.sin(angle), 0, 0,
									math.sin(angle), math.cos(angle), 0, 0,
									0, 0, 1, 0,
									0, 0, 0, 1})
					end
					-- Return this object
					return obj
				end,
				-- Inverses matrix
				inverse = function()
					-- Create inversion matrix
					local inv_matrix = {
						matrix[6] * matrix[11] * matrix[16] - matrix[6] * matrix[15] * matrix[12] - matrix[7] * matrix[10] * matrix[16] + matrix[7] * matrix[14] * matrix[12] +matrix[8] * matrix[10] * matrix[15] - matrix[8] * matrix[14] * matrix[11],
						-matrix[2] * matrix[11] * matrix[16] + matrix[2] * matrix[15] * matrix[12] + matrix[3] * matrix[10] * matrix[16] - matrix[3] * matrix[14] * matrix[12] - matrix[4] * matrix[10] * matrix[15] + matrix[4] * matrix[14] * matrix[11],
						matrix[2] * matrix[7] * matrix[16] - matrix[2] * matrix[15] * matrix[8] - matrix[3] * matrix[6] * matrix[16] + matrix[3] * matrix[14] * matrix[8] + matrix[4] * matrix[6] * matrix[15] - matrix[4] * matrix[14] * matrix[7],
						-matrix[2] * matrix[7] * matrix[12] + matrix[2] * matrix[11] * matrix[8] +matrix[3] * matrix[6] * matrix[12] - matrix[3] * matrix[10] * matrix[8] - matrix[4] * matrix[6] * matrix[11] + matrix[4] * matrix[10] * matrix[7],
						-matrix[5] * matrix[11] * matrix[16] + matrix[5] * matrix[15] * matrix[12] + matrix[7] * matrix[9] * matrix[16] - matrix[7] * matrix[13] * matrix[12] - matrix[8] * matrix[9] * matrix[15] + matrix[8] * matrix[13] * matrix[11],
						matrix[1] * matrix[11] * matrix[16] - matrix[1] * matrix[15] * matrix[12] - matrix[3] * matrix[9] * matrix[16] + matrix[3] * matrix[13] * matrix[12] + matrix[4] * matrix[9] * matrix[15] - matrix[4] * matrix[13] * matrix[11],
						-matrix[1] * matrix[7] * matrix[16] + matrix[1] * matrix[15] * matrix[8] + matrix[3] * matrix[5] * matrix[16] - matrix[3] * matrix[13] * matrix[8] - matrix[4] * matrix[5] * matrix[15] + matrix[4] * matrix[13] * matrix[7],
						matrix[1] * matrix[7] * matrix[12] - matrix[1] * matrix[11] * matrix[8] - matrix[3] * matrix[5] * matrix[12] + matrix[3] * matrix[9] * matrix[8] + matrix[4] * matrix[5] * matrix[11] - matrix[4] * matrix[9] * matrix[7],
						matrix[5] * matrix[10] * matrix[16] - matrix[5] * matrix[14] * matrix[12] - matrix[6] * matrix[9] * matrix[16] + matrix[6] * matrix[13] * matrix[12] + matrix[8] * matrix[9] * matrix[14] - matrix[8] * matrix[13] * matrix[10],
						-matrix[1] * matrix[10] * matrix[16] + matrix[1] * matrix[14] * matrix[12] + matrix[2] * matrix[9] * matrix[16] - matrix[2] * matrix[13] * matrix[12] - matrix[4] * matrix[9] * matrix[14] + matrix[4] * matrix[13] * matrix[10],
						matrix[1] * matrix[6] * matrix[16] - matrix[1] * matrix[14] * matrix[8] - matrix[2] * matrix[5] * matrix[16] + matrix[2] * matrix[13] * matrix[8] + matrix[4] * matrix[5] * matrix[14] - matrix[4] * matrix[13] * matrix[6],
						-matrix[1] * matrix[6] * matrix[12] + matrix[1] * matrix[10] * matrix[8] + matrix[2] * matrix[5] * matrix[12] - matrix[2] * matrix[9] * matrix[8] - matrix[4] * matrix[5] * matrix[10] + matrix[4] * matrix[9] * matrix[6],
						-matrix[5] * matrix[10] * matrix[15] + matrix[5] * matrix[14] * matrix[11] + matrix[6] * matrix[9] * matrix[15] - matrix[6] * matrix[13] * matrix[11] - matrix[7] * matrix[9] * matrix[14] + matrix[7] * matrix[13] * matrix[10],
						matrix[1] * matrix[10] * matrix[15] - matrix[1] * matrix[14] * matrix[11] - matrix[2] * matrix[9] * matrix[15] + matrix[2] * matrix[13] * matrix[11] + matrix[3] * matrix[9] * matrix[14] - matrix[3] * matrix[13] * matrix[10],
						-matrix[1] * matrix[6] * matrix[15] + matrix[1] * matrix[14] * matrix[7] + matrix[2] * matrix[5] * matrix[15] - matrix[2] * matrix[13] * matrix[7] - matrix[3] * matrix[5] * matrix[14] + matrix[3] * matrix[13] * matrix[6],
						matrix[1] * matrix[6] * matrix[11] - matrix[1] * matrix[10] * matrix[7] - matrix[2] * matrix[5] * matrix[11] + matrix[2] * matrix[9] * matrix[7] + matrix[3] * matrix[5] * matrix[10] - matrix[3] * matrix[9] * matrix[6]
					}
					-- Calculate determinant
					local det = matrix[1] * inv_matrix[1] +
									matrix[5] * inv_matrix[2] +
									matrix[9] * inv_matrix[3] +
									matrix[13] * inv_matrix[4]
					-- Matrix inversion possible?
					if det ~= 0 then
						-- Invert matrix
						det = 1 / det
						for i=1, 16 do
							matrix[i] = inv_matrix[i] * det
						end
						-- Return this object
						return obj
					end
				end,
				-- Applies matrix to point
				transform = function(x, y, z, w)
					-- Check arguments
					if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or (w ~= nil and type(w) ~= "number") then
						error("point (3 or 4 numbers) expected", 2)
					end
					-- Set 4th coordinate
					if not w then
						w = 1
					end
					-- Calculate new point
					return x * matrix[1] + y * matrix[5] + z * matrix[9] + w * matrix[13],
							x * matrix[2] + y * matrix[6] + z * matrix[10] + w * matrix[14],
							x * matrix[3] + y * matrix[7] + z * matrix[11] + w * matrix[15],
							x * matrix[4] + y * matrix[8] + z * matrix[12] + w * matrix[16]
				end
			}
			return obj
		end,
		-- Degree between two 3d vectors
		degree = function(x1, y1, z1, x2, y2, z2)
			-- Check arguments
			if type(x1) ~= "number" or type(y1) ~= "number" or type(z1) ~= "number" or
				type(x2) ~= "number" or type(y2) ~= "number" or type(z2) ~= "number" then
				error("2 vectors (as 6 numbers) expected", 2)
			end
			-- Calculate degree
			local degree = math.deg(
					math.acos(
						(x1 * x2 + y1 * y2 + z1 * z2) /
						(Yutils.math.distance(x1, y1, z1) * Yutils.math.distance(x2, y2, z2))
					)
			)
			-- Return with sign by clockwise direction
			return (x1*y2 - y1*x2) < 0 and -degree or degree
		end,
		-- Length of vector
		distance = function(x, y, z)
			-- Check arguments
			if type(x) ~= "number" or type(y) ~= "number" or (z ~= nil and type(z) ~= "number") then
				error("one vector (2 or 3 numbers) expected", 2)
			end
			-- Calculate length
			return z and math.sqrt(x*x + y*y + z*z) or math.sqrt(x*x + y*y)
		end,
		-- Get orthogonal vector of 2 given vectors
		ortho = function(x1, y1, z1, x2, y2, z2)
			-- Check arguments
			if type(x1) ~= "number" or type(y1) ~= "number" or type(z1) ~= "number" or
				type(x2) ~= "number" or type(y2) ~= "number" or type(z2) ~= "number" then
				error("2 vectors (as 6 numbers) expected", 2)
			end
			-- Calculate orthogonal
			return y1 * z2 - z1 * y2,
				z1 * x2 - x1 * z2,
				x1 * y2 - y1 * x2
		end,
		-- Generates a random number in given range with specific item distance
		randomsteps = function(min, max, step)
			-- Check arguments
			if type(min) ~= "number" or type(max) ~= "number" or type(step) ~= "number" or max < min or step <= 0 then
				error("minimal, maximal and step number expected", 2)
			end
			-- Generate random number
			return math.min(min + math.random(0, math.ceil((max - min) / step)) * step, max)
		end,
		-- Rounds number
		round = function(x)
			-- Check argument
			if type(x) ~= "number" then
				error("number expected", 2)
			end
			-- Return number rounded to nearest integer
			return math.floor(x + 0.5)
		end,
		-- Scales vector to given length
		stretch = function(x, y, z, length)
			-- Check arguments
			if type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or type(length) ~= "number" then
				error("vector (3d) and length expected", 2)
			end
			-- Get current vector length
			local cur_length = Yutils.math.distance(x, y, z)
			-- Scale vector to new length
			if cur_length == 0 then
				return 0, 0, 0
			else
				local factor = length / cur_length
				return x * factor, y * factor, z * factor
			end
		end,
		-- Trim number in range
		trim = function(x, min, max)
			-- Check arguments
			if type(x) ~= "number" or type(min) ~= "number" or type(max) ~= "number" then
				error("3 numbers expected", 2)
			end
			-- Limit number bigger-equal minimal value and smaller-equal maximal value
			return x < min and min or x > max and max or x
		end
	},
	-- Algorithm sublibrary
	algorithm = {
		-- Creates iterator through frame times
		frames = function(starts, ends, dur)
			-- Check arguments
			if type(starts) ~= "number" or type(ends) ~= "number" or type(dur) ~= "number" or dur == 0 then
				error("start, end and duration number expected", 2)
			end
			-- Iteration state
			local i, n = 0, math.ceil((ends - starts) / dur)
			-- Return iterator
			return function()
				i = i + 1
				if i > n then
					return
				else
					local ret_starts = starts + (i-1) * dur
					local ret_ends = ret_starts + dur
					if dur < 0 and ret_ends < ends then
						ret_ends = ends
					elseif dur > 0 and ret_ends > ends then
						ret_ends = ends
					end
					return ret_starts, ret_ends, i, n
				end
			end
		end,
		-- Creates iterator through text lines
		lines = function(text)
			-- Check argument
			if type(text) ~= "string" then
				error("string expected", 2)
			end
			-- Return iterator
			return function()
				-- Still text left?
				if text then
					-- Find possible line endings
					local cr = text:find("\r", 1, true)
					local lf = text:find("\n", 1, true)
					-- Find earliest line ending
					local text_end, next_step = #text, 0
					if lf then
						text_end, next_step = lf-1, 2
					end
					if cr then
						if not lf or cr < lf-1 then
							text_end, next_step = cr-1, 2
						elseif cr == lf-1 then
							text_end, next_step = cr-1, 3
						end
					end
					-- Cut line out & update text
					local line = text:sub(1, text_end)
					if next_step == 0 then
						text = nil
					else
						text = text:sub(text_end+next_step)
					end
					-- Return current line
					return line
				end
			end
		end
	},
	-- Shape sublibrary
	shape = {
		-- Calculates shape bounding box
		bounding = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- Bounding data
			local x0, y0, x1, y1
			-- Calculate minimal and maximal coordinates
			Yutils.shape.filter(shape, function(x, y)
				x0 = x0 and math.min(x0, x) or x
				y0 = y0 and math.min(y0, y) or y
				x1 = x1 and math.max(x1, x) or x
				y1 = y1 and math.max(y1, y) or y
			end)
			return x0, y0, x1, y1
		end,
		-- Extracts shapes by similar data in 2d data map
		detect = function(width, height, data, compare_func)
			-- Check arguments
			if type(width) ~= "number" or math.floor(width) ~= width or width < 1 or type(height) ~= "number" or math.floor(height) ~= height or height < 1 or type(data) ~= "table" or #data < width * height or (compare_func ~= nil and type(compare_func) ~= "function") then
				error("width, height, data and optional data compare function expected", 2)
			end
			-- Set default comparator
			if not compare_func then
				compare_func = function(a, b) return a == b end
			end
			-- Maximal data number to be processed
			local data_n = width * height
			-- Collect unique data elements
			local elements = {n = 1, {value = data[1]}}
			for i=2, data_n do
				for j=1, elements.n do
					if compare_func(data[i], elements[j].value) then
						goto element_found
					end
				end
				elements.n = elements.n + 1
				elements[elements.n] = {value = type(data[i]) == "table" and Yutils.table.copy(data[i]) or data[i]}
				::element_found::
			end
			-- Detection helper functions
			local function index_to_x(i)
				return (i-1) % width
			end
			local function index_to_y(i)
				return math.floor((i-1) / width)
			end
			local function coord_to_index(x, y)
				return 1 + x + y * width
			end
			local function find_direction(bitmap, x, y, last_direction)
				local top_left, top_right, bottom_left, bottom_right =
					x-1 >= 0 and y-1 >= 0 and bitmap[coord_to_index(x-1,y-1)] == 1 or false,
					x < width and y-1 >= 0 and bitmap[coord_to_index(x,y-1)] == 1 or false,
					x-1 >= 0 and y < height and bitmap[coord_to_index(x-1,y)] == 1 or false,
					x < width and y < height and bitmap[coord_to_index(x,y)] == 1 or false
				return last_direction == 8 and (
						bottom_left and (
							top_left and top_right and 6 or
							top_left and 8 or
							4
						) or (	-- bottom_right
							top_left and top_right and 4 or
							top_right and 8 or
							6
						)
					) or last_direction == 6 and (
						top_left and (
							top_right and bottom_right and 2 or
							top_right and 6 or
							8
						)or (	-- bottom_left
							top_right and bottom_right and 8 or
							bottom_right and 6 or
							2
						)
					) or last_direction == 2 and (
						top_left and (
							bottom_left and bottom_right and 6 or
							bottom_left and 2 or
							4
						) or (	-- top_right
							bottom_left and bottom_right and 4 or
							bottom_right and 2 or
							6
						)
					) or last_direction == 4 and (
						top_right and (
							top_left and bottom_left and 2 or
							top_left and 4 or
							8
						) or (	-- bottom_right
							top_left and bottom_left and 8 or
							bottom_left and 4 or
							2
						)
					)
			end
			local function extract_contour(bitmap, x, y, cw)
				local contour, direction = {n = 1, cw and {x1 = x, y1 = y+1, x2 = x, y2 = y, direction = 8} or {x1 = x, y1 = y, x2 = x, y2 = y+1, direction = 2}}
				repeat
					x, y = contour[contour.n].x2, contour[contour.n].y2
					direction = find_direction(bitmap, x, y, contour[contour.n].direction)
					contour.n = contour.n + 1
					contour[contour.n] = {x1 = x, y1 = y, x2 = direction == 4 and x-1 or direction == 6 and x+1 or x, y2 = direction == 8 and y-1 or direction == 2 and y+1 or y, direction = direction}
				until contour[contour.n].x2 == contour[1].x1 and contour[contour.n].y2 == contour[1].y1
				return contour
			end
			local function contour_indices(contour)
				-- Get top & bottom line of contour
				local min_y, max_y, line
				for i=1, contour.n do
					line = contour[i]
					if line.direction == 8 then
						min_y, max_y = min_y and math.min(min_y, line.y2) or line.y2, max_y and math.max(max_y, line.y2) or line.y2
					elseif line.direction == 2 then
						min_y, max_y = min_y and math.min(min_y, line.y1) or line.y1, max_y and math.max(max_y, line.y1) or line.y1
					end
				end
				-- Get indices by scanlines
				local indices, h_stops, h_stops_n, j = {n = 0}
				for y=min_y, max_y do
					h_stops, h_stops_n = {}, 0
					for i=1, contour.n do
						line = contour[i]
						if line.direction == 8 and line.y2 == y or line.direction == 2 and line.y1 == y then
							h_stops_n = h_stops_n + 1
							h_stops[h_stops_n] = line.x1
						end
					end
					table.sort(h_stops)
					for i=1, h_stops_n, 2 do
						j = coord_to_index(h_stops[i], y)
						for x_off=0, h_stops[i+1] - h_stops[i] - 1 do
							indices.n = indices.n + 1
							indices[indices.n] = j + x_off
						end
					end
				end
				return indices
			end
			local function merge_contour_lines(contour)
				local i = 1
				while i < contour.n do
					if contour[i].direction == contour[i+1].direction then
						contour[i].x2, contour[i].y2 = contour[i+1].x2, contour[i+1].y2
						table.remove(contour, i+1)
						contour.n = contour.n - 1
					else
						i = i + 1
					end
				end
				if contour.n > 1 and contour[1].direction == contour[contour.n].direction then
					contour[1].x1, contour[1].y1 = contour[contour.n].x1, contour[contour.n].y1
					table.remove(contour)
					contour.n = contour.n - 1
				end
				return contour
			end
			local function contour_to_shape(contour)
				local shape, shape_n, line = {string.format("m %d %d l", contour[1].x1, contour[1].y1)}, 1
				for i=1, contour.n do
					line = contour[i]
					shape_n = shape_n + 1
					shape[shape_n] = string.format("%d %d", line.x2, line.y2)
				end
				return table.concat(shape, " ")
			end
			-- Find shapes for elements
			local element, element_shapes, shape, shape_n, element_contour, element_hole_contour, indices, hole_indices
			local bitmap = {}
			for i=1, elements.n do
				element, element_shapes = elements[i].value, {n = 0}
				-- Create bitmap of data for current element
				for i=1, data_n do
					bitmap[i] = compare_func(data[i], element) and 1 or 0
				end
				-- Find first upper-left element of shapes
				for i=1, data_n do
					if bitmap[i] == 1 then
						-- Detect contour
						element_contour = extract_contour(bitmap, index_to_x(i), index_to_y(i), true)
						indices = contour_indices(element_contour)
						shape, shape_n = {contour_to_shape(merge_contour_lines(element_contour))}, 1
						-- Detect contour holes
						for i=1, indices.n do
							i = indices[i]
							if bitmap[i] == 0 then
								element_hole_contour = extract_contour(bitmap, index_to_x(i), index_to_y(i), false)
								hole_indices = contour_indices(element_hole_contour)
								shape_n = shape_n + 1
								shape[shape_n] = contour_to_shape(merge_contour_lines(element_hole_contour))
								for i=1, hole_indices.n do
									i = hole_indices[i]
									bitmap[i] = bitmap[i] + 1
								end
							end
						end
						-- Remove contour from bitmap
						for i=1, indices.n do
							i = indices[i]
							bitmap[i] = bitmap[i] - 1
						end
						-- Add shape to element
						element_shapes.n = element_shapes.n + 1
						element_shapes[element_shapes.n] = table.concat(shape, " ")
					end
				end
				-- Set shapes to element
				elements[i].shapes = element_shapes
			end
			-- Return shapes by element
			return elements
		end,
		-- Filters shape points
		filter = function(shape, filter)
			-- Check arguments
			if type(shape) ~= "string" or type(filter) ~= "function" then
				error("shape and filter function expected", 2)
			end
			-- Iterate through space separated tokens
			local token_start, token_end, token, token_num = 1
			local point_start, typ, x, new_point
			repeat
				token_start, token_end, token = shape:find("([^%s]+)", token_start)
				if token_start then
					-- Continue by token type / is number
					token_num = tonumber(token)
					if not token_num then
						-- Set point type
						point_start, typ, x = token_start, token
					else
						-- Set point coordinate
						if not x then
							-- Set x coordinate
							if not point_start then
								point_start = token_start
							end
							x = token_num
						else
							-- Apply filter on completed point
							x, token_num = filter(x, token_num, typ)
							-- Point to replace?
							if type(x) == "number" and type(token_num) == "number" then
								new_point = typ and string.format("%s %s %s", typ, roundf(x), roundf(token_num)) or
												string.format("%s %s", roundf(x), roundf(token_num))
								shape = string.format("%s%s%s", shape:sub(1, point_start-1), new_point, shape:sub(token_end+1))
								token_end = point_start + #new_point - 1
							end
							-- Reset point / prepare next one
							point_start, typ, x = nil
						end
					end
					-- Increase shape start position to next possible token
					token_start = token_end + 1
				end
			until not token_start
			-- Return (modified) shape
			return shape
		end,
		-- Converts shape curves to lines
		flatten = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- 4th degree curve subdivider
			local function curve4_subdivide(x0, y0, x1, y1, x2, y2, x3, y3, pct)
				-- Calculate points on curve vectors
				local x01, y01, x12, y12, x23, y23 = (x0+x1)*pct, (y0+y1)*pct, (x1+x2)*pct, (y1+y2)*pct, (x2+x3)*pct, (y2+y3)*pct
				local x012, y012, x123, y123 = (x01+x12)*pct, (y01+y12)*pct, (x12+x23)*pct, (y12+y23)*pct
				local x0123, y0123 = (x012+x123)*pct, (y012+y123)*pct
				-- Return new 2 curves
				return x0, y0, x01, y01, x012, y012, x0123, y0123,
						x0123, y0123, x123, y123, x23, y23, x3, y3
			end
			-- Check flatness of 4th degree curve with angles
			local function curve4_is_flat(x0, y0, x1, y1, x2, y2, x3, y3, tolerance)
				-- Pack curve vectors
				local vecs = {{x1 - x0, y1 - y0}, {x2 - x1, y2 - y1}, {x3 - x2, y3 - y2}}
				-- Remove zero length vectors
				local i, n = 1, #vecs
				while i <= n do
					if vecs[i][1] == 0 and vecs[i][2] == 0 then
						table.remove(vecs, i)
						n = n - 1
					else
						i = i + 1
					end
				end
				-- Check flatness on remaining vectors
				for i=2, n do
					if math.abs(Yutils.math.degree(vecs[i-1][1], vecs[i-1][2], 0, vecs[i][1], vecs[i][2], 0)) > tolerance then
						return false
					end
				end
				return true
			end
			-- Convert 4th degree curve to line points
			local function curve4_to_lines(x0, y0, x1, y1, x2, y2, x3, y3)
				-- Line points buffer
				local pts, pts_n = {x0, y0}, 2
				-- Conversion in recursive processing
				local function convert_recursive(x0, y0, x1, y1, x2, y2, x3, y3)
					if curve4_is_flat(x0, y0, x1, y1, x2, y2, x3, y3, CURVE_TOLERANCE) then
						pts[pts_n+1] = x3
						pts[pts_n+2] = y3
						pts_n = pts_n + 2
					else
						local x10, y10, x11, y11, x12, y12, x13, y13, x20, y20, x21, y21, x22, y22, x23, y23 = curve4_subdivide(x0, y0, x1, y1, x2, y2, x3, y3, 0.5)
						convert_recursive(x10, y10, x11, y11, x12, y12, x13, y13)
						convert_recursive(x20, y20, x21, y21, x22, y22, x23, y23)
					end
				end
				convert_recursive(x0, y0, x1, y1, x2, y2, x3, y3)
				-- Return resulting points
				return pts
			end
			-- Search for curves
			local curves_start, curves_end, x0, y0 = 1
			local curve_start, curve_end, x1, y1, x2, y2, x3, y3
			local line_points, line_curve
			repeat
				curves_start, curves_end, x0, y0 = shape:find("([^%s]+)%s+([^%s]+)%s+b%s+", curves_start)
				x0, y0 = tonumber(x0), tonumber(y0)
				-- Curve(s) found!
				if x0 and y0 then
					-- Replace curves type by lines type
					shape = shape:sub(1, curves_start-1) .. shape:sub(curves_start):gsub("b", "l", 1)
					-- Search for single curves
					curve_start = curves_end + 1
					repeat
						curve_start, curve_end, x1, y1, x2, y2, x3, y3 = shape:find("([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+([^%s]+)", curve_start)
						x1, y1, x2, y2, x3, y3 = tonumber(x1), tonumber(y1), tonumber(x2), tonumber(y2), tonumber(x3), tonumber(y3)
						if x1 and y1 and x2 and y2 and x3 and y3 then
							-- Convert curve to lines
							local line_points = curve4_to_lines(x0, y0, x1, y1, x2, y2, x3, y3)
							for i=1, #line_points do
								line_points[i] = roundf(line_points[i])
							end
							line_curve = table.concat(line_points, " ")
							shape = string.format("%s%s%s", shape:sub(1, curve_start-1), line_curve, shape:sub(curve_end+1))
							curve_end = curve_start + #line_curve - 1
							-- Set next start point to current last point
							x0, y0 = x3, y3
							-- Increase search start position to next possible curve
							curve_start = curve_end + 1
						end
					until not (x1 and y1 and x2 and y2 and x3 and y3)
					-- Increase search start position to next possible curves
					curves_start = curves_end + 1
				end
			until not (x0 and y0)
			-- Return shape without curves
			return shape
		end,
		-- Projects shape on shape
		glue = function(src_shape, dst_shape, transform_callback)
			-- Check arguments
			if type(src_shape) ~= "string" or type(dst_shape) ~= "string" or (transform_callback ~= nil and type(transform_callback) ~= "function") then
				error("2 shapes and optional callback function expected", 2)
			end
			-- Trim destination shape to first figure
			local _, figure_end = dst_shape:find("^%s*m.-m")
			if figure_end then
				dst_shape = dst_shape:sub(1, figure_end - 1)
			end
			-- Collect destination shape/figure lines + lengths
			local dst_lines, dst_lines_n = {}, 0
			local dst_lines_length, dst_line, last_point = 0
			Yutils.shape.filter(Yutils.shape.flatten(dst_shape), function(x, y)
				if last_point then
					dst_line = {last_point[1], last_point[2], x - last_point[1], y - last_point[2], Yutils.math.distance(x - last_point[1], y - last_point[2])}
					if dst_line[5] > 0 then
						dst_lines_n = dst_lines_n + 1
						dst_lines[dst_lines_n] = dst_line
						dst_lines_length = dst_lines_length + dst_line[5]
					end
				end
				last_point = {x, y}
			end)
			-- Any destination line?
			if dst_lines_n > 0 then
				-- Add relative positions to destination lines
				local cur_length = 0
				for _, dst_line in ipairs(dst_lines) do
					dst_line[6] = cur_length / dst_lines_length
					cur_length = cur_length + dst_line[5]
					dst_line[7] = cur_length / dst_lines_length
				end
				-- Get source shape exact bounding box
				local x0, _, x1, y1 = Yutils.shape.bounding(Yutils.shape.flatten(src_shape))
				-- Source shape has body?
				if x0 and x1 > x0 then
					-- Source shape width
					local w = x1 - x0
					-- Shift source shape on destination shape
					local x_pct, y_off, x_pct_temp, y_off_temp
					local dst_line_pos, ovec_x, ovec_y
					return Yutils.shape.filter(src_shape, function(x, y)
						-- Get relative source point to baseline
						x_pct, y_off = (x - x0) / w, y - y1
						if transform_callback then
							x_pct_temp, y_off_temp = transform_callback(x_pct, y_off)
							if type(x_pct_temp) == "number" and type(y_off_temp) == "number" then
								x_pct, y_off = math.max(0, math.min(x_pct_temp, 1)), y_off_temp
							end
						end
						-- Search for destination point, relative to source point
						for i=1, dst_lines_n do
							dst_line = dst_lines[i]
							if x_pct >= dst_line[6] and x_pct <= dst_line[7] then
								dst_line_pos = (x_pct - dst_line[6]) / (dst_line[7] - dst_line[6])
								-- Span orthogonal vector to baseline for final source to destination projection
								ovec_x, ovec_y = Yutils.math.ortho(dst_line[3], dst_line[4], 0, 0, 0, -1)
								ovec_x, ovec_y = Yutils.math.stretch(ovec_x, ovec_y, 0, y_off)
								return dst_line[1] + dst_line_pos * dst_line[3] + ovec_x,
										dst_line[2] + dst_line_pos * dst_line[4] + ovec_y
							end
						end
					end)
				end
			end
		end,
		-- Shifts shape coordinates
		move = function(shape, x, y)
			-- Check arguments
			if type(shape) ~= "string" or type(x) ~= "number" or type(y) ~= "number" then
				error("shape, horizontal shift and vertical shift expected", 2)
			end
			-- Shift!
			return Yutils.shape.filter(shape, function(cx, cy)
				return cx + x, cy + y
			end)
		end,
		-- Splits shape lines into shorter segments
		split = function(shape, max_len)
			-- Check arguments
			if type(shape) ~= "string" or type(max_len) ~= "number" or max_len <= 0 then
				error("shape and maximal line length expected", 2)
			end
			-- Remove shape closings (figures become line-completed)
			shape = shape:gsub("%s+c", "")
			-- Line splitter + string encoder
			local function line_split(x0, y0, x1, y1)
				-- Line direction & length
				local rel_x, rel_y = x1 - x0, y1 - y0
				local distance = Yutils.math.distance(rel_x, rel_y)
				-- Line too long -> split!
				if distance > max_len then
					-- Generate line segments
					local lines, lines_n, distance_rest, pct = {}, 0, distance % max_len
					for cur_distance = distance_rest > 0 and distance_rest or max_len, distance, max_len do
						pct = cur_distance / distance
						lines_n = lines_n + 1
						lines[lines_n] = string.format("%s %s", roundf(x0 + rel_x * pct), roundf(y0 + rel_y * pct))
					end
					return table.concat(lines, " ")
				-- No line split
				else
					return string.format("%s %s", roundf(x1), roundf(y1))
				end
			end
			-- Build new shape with shorter lines
			local new_shape, new_shape_n = {}, 0
			local line_mode, last_point, last_move
			Yutils.shape.filter(shape, function(x, y, typ)
				-- Close last figure of new shape
				if typ == "m" and last_move and not (last_point[1] == last_move[1] and last_point[2] == last_move[2]) then
					if not line_mode then
						new_shape_n = new_shape_n + 1
						new_shape[new_shape_n] =  "l"
					end
					new_shape_n = new_shape_n + 1
					new_shape[new_shape_n] = line_split(last_point[1], last_point[2], last_move[1], last_move[2])
				end
				-- Add current type to new shape
				if typ then
					new_shape_n = new_shape_n + 1
					new_shape[new_shape_n] = typ
				end
				-- En-/disable line mode by current type
				if typ then
					line_mode = typ == "l"
				end
				-- Add current point or splitted line to new shape
				new_shape_n = new_shape_n + 1
				new_shape[new_shape_n] = line_mode and last_point and line_split(last_point[1], last_point[2], x, y) or string.format("%s %s", roundf(x), roundf(y))
				-- Update last point & move
				last_point = {x, y}
				if typ == "m" then
					last_move = {x, y}
				end
			end)
			-- Close last figure of new shape
			if last_move and not (last_point[1] == last_move[1] and last_point[2] == last_move[2]) then
				if not line_mode then
					new_shape_n = new_shape_n + 1
					new_shape[new_shape_n] =  "l"
				end
				new_shape_n = new_shape_n + 1
				new_shape[new_shape_n] = line_split(last_point[1], last_point[2], last_move[1], last_move[2])
			end
			return table.concat(new_shape, " ")
		end,
		-- Converts shape to stroke version
		to_outline = function(shape, width_xy, width_y)
			-- Check arguments
			if type(shape) ~= "string" or type(width_xy) ~= "number" or width_xy < 0 or not (width_y == nil or type(width_y) == "number" and width_y >= 0) then
				error("shape and line width (general or horizontal and vertical) expected", 2)
			elseif width_y and not (width_xy > 0 or width_y > 0) or width_xy == 0 then
				error("one width must be >0", 2)
			end
			-- Line width values
			local width, xscale, yscale
			if width_y and width_xy ~= width_y then
				width = math.max(width_xy, width_y)
				xscale, yscale = width_xy / width, width_y / width
			else
				width, xscale, yscale = width_xy, 1, 1
			end
			-- Collect figures
			local figures, figures_n, figure, figure_n = {}, 0, {}, 0
			local last_move
			Yutils.shape.filter(shape, function(x, y, typ)
				-- Check point type
				if typ and not (typ == "m" or typ == "l") then
					error("shape have to contain only \"moves\" and \"lines\"", 2)
				end
				-- New figure?
				if not last_move or typ == "m" then
					-- Enough points in figure?
					if figure_n > 2 then
						-- Last point equal to first point? (yes: remove him)
						if last_move and figure[figure_n][1] == last_move[1] and figure[figure_n][2] == last_move[2] then
							figure[figure_n] = nil
						end
						-- Save figure
						figures_n = figures_n + 1
						figures[figures_n] = figure
					end
					-- Clear figure for new one
					figure, figure_n = {}, 0
					-- Save last move for figure closing check
					last_move = {x, y}
				end
				-- Add point to current figure (if not copy of last)
				if figure_n == 0 or not(figure[figure_n][1] == x and figure[figure_n][2] == y) then
					figure_n = figure_n + 1
					figure[figure_n] = {x, y}
				end
			end)
			-- Insert last figure (with enough points)
			if figure_n > 2 then
				-- Last point equal to first point? (yes: remove him)
				if last_move and figure[figure_n][1] == last_move[1] and figure[figure_n][2] == last_move[2] then
					figure[figure_n] = nil
				end
				-- Save figure
				figures_n = figures_n + 1
				figures[figures_n] = figure
			end
			-- Create stroke shape out of figures
			local stroke_shape, stroke_shape_n = {}, 0
			for fi, figure in ipairs(figures) do
				-- One pass for inner, one for outer outline
				for i = 1, 2 do
					-- Outline buffer
					local outline, outline_n = {}, 0
					-- Point iteration order = inner or outer outline
					local loop_begin, loop_end, loop_steps
					if i == 1 then
						loop_begin, loop_end, loop_step = #figure, 1, -1
					else
						loop_begin, loop_end, loop_step = 1, #figure, 1
					end
					-- Iterate through figure points
					for pi = loop_begin, loop_end, loop_step do
						-- Collect current, previous and next point
						local point = figure[pi]
						local pre_point, post_point
						if i == 1 then
							if pi == 1 then
								pre_point = figure[pi+1]
								post_point = figure[#figure]
							elseif pi == #figure then
								pre_point = figure[1]
								post_point = figure[pi-1]
							else
								pre_point = figure[pi+1]
								post_point = figure[pi-1]
							end
						else
							if pi == 1 then
								pre_point = figure[#figure]
								post_point = figure[pi+1]
							elseif pi == #figure then
								pre_point = figure[pi-1]
								post_point = figure[1]
							else
								pre_point = figure[pi-1]
								post_point = figure[pi+1]
							end
						end
						-- Calculate orthogonal vectors to both neighbour points
						local o_vec1_x, o_vec1_y = Yutils.math.ortho(point[1]-pre_point[1], point[2]-pre_point[2], 0, 0, 0, 1)
						o_vec1_x, o_vec1_y = Yutils.math.stretch(o_vec1_x, o_vec1_y, 0, width)
						local o_vec2_x, o_vec2_y = Yutils.math.ortho(post_point[1]-point[1], post_point[2]-point[2], 0, 0, 0, 1)
						o_vec2_x, o_vec2_y = Yutils.math.stretch(o_vec2_x, o_vec2_y, 0, width)
						-- Calculate degree & circumference between orthogonal vectors
						local degree = Yutils.math.degree(o_vec1_x, o_vec1_y, 0, o_vec2_x, o_vec2_y, 0)
						local circ = math.abs(math.rad(degree)) * width
						-- Add first edge point
						outline_n = outline_n + 1
						outline[outline_n] = string.format("%s%s %s",
																	outline_n == 1 and "m " or outline_n == 2 and "l " or "",
																	roundf(point[1] + o_vec1_x * xscale), roundf(point[2] + o_vec1_y * yscale))
						-- Round edge needed?
						if circ > MAX_CIRCUMFERENCE then
							local circ_rest = circ % MAX_CIRCUMFERENCE
							for cur_circ = circ_rest > 0 and circ_rest or MAX_CIRCUMFERENCE, circ, MAX_CIRCUMFERENCE do
								local curve_vec_x, curve_vec_y = rotate2d(o_vec1_x, o_vec1_y, cur_circ / circ * degree)
								outline_n = outline_n + 1
								outline[outline_n] = string.format("%s%s %s",
																			outline_n == 1 and "m " or outline_n == 2 and "l " or "",
																			roundf(point[1] + curve_vec_x * xscale), roundf(point[2] + curve_vec_y * yscale))
							end
						end
					end
					-- Insert inner or outer outline to stroke shape
					stroke_shape_n = stroke_shape_n + 1
					stroke_shape[stroke_shape_n] = table.concat(outline, " ")
				end
			end
			return table.concat(stroke_shape, " ")
		end,
		-- Converts shape to pixels
		to_pixels = function(shape)
			-- Check argument
			if type(shape) ~= "string" then
				error("shape expected", 2)
			end
			-- Scale values for supersampled rendering
			local upscale = SUPERSAMPLING
			local downscale = 1 / upscale
			-- Upscale shape for later downsampling
			shape = Yutils.shape.filter(shape, function(x, y)
				return x * upscale, y * upscale
			end)
			-- Get shape bounding
			local x1, y1, x2, y2 = Yutils.shape.bounding(shape)
			if not y2 then
				error("not enough shape points", 2)
			end
			-- Bring shape near origin in positive room
			local shift_x, shift_y = -(x1 - x1 % upscale), -(y1 - y1 % upscale)
			shape = Yutils.shape.move(shape, shift_x, shift_y)
			-- Renderer (on binary image with aliasing)
			local function render_shape(width, height, image, shape)
				-- Collect lines (points + vectors)
				local lines, lines_n, last_point, last_move = {}, 0
				Yutils.shape.filter(Yutils.shape.flatten(shape), function(x, y, typ)
					x, y = Yutils.math.round(x), Yutils.math.round(y)	-- Use integers to avoid rounding errors
					-- Move
					if typ == "m" then
						-- Close figure with non-horizontal line in image
						if last_move and last_move[2] ~= last_point[2] and not (last_point[2] < 0 and last_move[2] < 0) and not (last_point[2] > height and last_move[2] > height) then
							lines_n = lines_n + 1
							lines[lines_n] = {last_point[1], last_point[2], last_move[1] - last_point[1], last_move[2] - last_point[2]}
						end
						last_move = {x, y}
					-- Non-horizontal line in image
					elseif last_point and last_point[2] ~= y and not (last_point[2] < 0 and y < 0) and not (last_point[2] > height and y > height) then
						lines_n = lines_n + 1
						lines[lines_n] = {last_point[1], last_point[2], x - last_point[1], y - last_point[2]}
					end
					-- Remember last point
					last_point = {x, y}
				end)
				-- Close last figure with non-horizontal line in image
				if last_move and last_move[2] ~= last_point[2] and not (last_point[2] < 0 and last_move[2] < 0) and not (last_point[2] > height and last_move[2] > height) then
					lines_n = lines_n + 1
					lines[lines_n] = {last_point[1], last_point[2], last_move[1] - last_point[1], last_move[2] - last_point[2]}
				end
				-- Calculates line x horizontal line intersection
				local function line_x_hline(x, y, vx, vy, y2)
					if vy ~= 0 then
						local s = (y2 - y) / vy
						if s >= 0 and s <= 1 then
							return x + s * vx, y2
						end
					end
				end
				-- Scan image rows in shape
				local _, y1, _, y2 = Yutils.shape.bounding(shape)
				for y = math.max(math.floor(y1), 0), math.min(math.ceil(y2), height)-1 do
					-- Collect row intersections with lines
					local row_stops, row_stops_n = {}, 0
					for i=1, lines_n do
						local line = lines[i]
						local cx = line_x_hline(line[1], line[2], line[3], line[4], y + 0.5)
						if cx then
							row_stops_n = row_stops_n + 1
							row_stops[row_stops_n] = {Yutils.math.trim(cx, 0, width), line[4] > 0 and 1 or -1}	-- image trimmed stop position & line vertical direction
						end
					end
					-- Enough intersections / something to render?
					if row_stops_n > 1 then
						-- Sort row stops by horizontal position
						table.sort(row_stops, function(a, b)
							return a[1] < b[1]
						end)
						-- Render!
						local status, row_index = 0, 1 + y * width
						for i = 1, row_stops_n-1 do
							status = status + row_stops[i][2]
							if status ~= 0 then
								for x=math.ceil(row_stops[i][1]-0.5), math.floor(row_stops[i+1][1]+0.5)-1 do
									image[row_index + x] = true
								end
							end
						end
					end
				end
			end
			-- Create image
			local img_width, img_height, img_data = math.ceil((x2 + shift_x) * downscale) * upscale, math.ceil((y2 + shift_y) * downscale) * upscale, {}
			for i=1, img_width*img_height do
				img_data[i] = false
			end
			-- Render shape on image
			render_shape(img_width, img_height, img_data, shape)
			-- Extract pixels from image
			local pixels, pixels_n, opacity = {}, 0
			for y=0, img_height-upscale, upscale do
				for x=0, img_width-upscale, upscale do
					opacity = 0
					for yy=0, upscale-1 do
						for xx=0, upscale-1 do
							if img_data[1 + (y+yy) * img_width + (x+xx)] then
								opacity = opacity + 255
							end
						end
					end
					if opacity > 0 then
						pixels_n = pixels_n + 1
						pixels[pixels_n] = {
							alpha = opacity * (downscale * downscale),
							x = (x - shift_x) * downscale,
							y = (y - shift_y) * downscale
						}
					end
				end
			end
			return pixels
		end,
		-- Applies matrix to shape coordinates
		transform = function(shape, matrix)
			-- Check arguments
			if type(shape) ~= "string" or type(matrix) ~= "table" or type(matrix.transform) ~= "function" then
				error("shape and matrix expected", 2)
			end
			local success, x, y, z, w = pcall(matrix.transform, 1, 1, 1)
			if not success or type(x) ~= "number" or type(y) ~= "number" or type(z) ~= "number" or type(w) ~= "number" then
				error("matrix transform method invalid", 2)
			end
			-- Filter shape with matrix
			return Yutils.shape.filter(shape, function(x, y)
				x, y, z, w = matrix.transform(x, y, 0)
				return x / w, y / w
			end)
		end
	},
	-- Decoder sublibrary
	decode = {
		-- Creates BMP file reader
		create_bmp_reader = function(filename)
			-- Check argument
			if type(filename) ~= "string" then
				error("bmp filename expected", 2)
			end
			-- Convert little-endian bytes string to Lua number
			local function bton(s)
				local bytes, n = {s:byte(1,#s)}, 0
				for i = 0, #bytes-1 do
					n = n + bytes[1+i] * 2^(i*8)
				end
				return n
			end
			-- Open file handle
			local file = io.open(filename, "rb")
			if not file then
				error(string.format("couldn't open file %q", filename), 2)
			end
			-- Read bitmap header
			if file:read(2) ~= "BM" then
				error("not a windows bitmap file", 2)
			end
			local file_size = file:read(4)
			if not file_size then
				error("file size not found", 2)
			end
			file_size = bton(file_size)
			file:seek("cur", 4)	-- skip application reserved bytes
			local data_offset = file:read(4)
			if not data_offset then
				error("data offset not found", 2)
			end
			data_offset = bton(data_offset)
			-- DIB Header
			file:seek("cur", 4)	-- skip header size
			local width = file:read(4)
			if not width then
				error("width not found", 2)
			end
			width = bton(width)
			if width >= 2^31 then
				error("pixels in right-to-left order not supported", 2)
			end
			local height = file:read(4)
			if not height then
				error("height not found", 2)
			end
			height = bton(height)
			if height >= 2^31 then
				height = height - 2^32
			end
			local planes = file:read(2)
			if not planes or bton(planes) ~= 1 then
				error("planes must be 1", 2)
			end
			local bit_depth = file:read(2)
			if not bit_depth then
				error("bit depth not found", 2)
			end
			bit_depth = bton(bit_depth)
			if bit_depth ~= 24 and bit_depth ~= 32 then
				error("bit depth must be 24 or 32", 2)
			end
			local compression = file:read(4)
			if not compression or bton(compression) ~= 0 then
				error("must be uncompressed RGB", 2)
			end
			local data_size = file:read(4)
			if not data_size then
				error("data size not found", 2)
			end
			data_size = bton(data_size)
			if data_size == 0 then
				error("data size must not be zero", 2)
			end
			-- Data
			file:seek("set", data_offset)
			local data = file:read(data_size)
			if not data or #data ~= data_size then
				error("not enough data", 2)
			end
			-- All data read from file -> close handle (don't wait for GC)
			file:close()
			-- Calculate row size (round up to multiple of 4)
			local row_size = math.floor((bit_depth * width + 31) / 32) * 4
			-- Return bitmap object
			local obj
			obj = {
				file_size = function()
					return file_size
				end,
				width = function()
					return width
				end,
				height = function()
					return height
				end,
				bit_depth = function()
					return bit_depth
				end,
				data_size = function()
					return data_size
				end,
				row_size = function()
					return row_size
				end,
				data_raw = function()
					return data
				end,
				data_packed = function()
					local data_packed, data_packed_n = {}, 0
					local first_row, last_row, row_step
					if height < 0 then
						first_row, last_row, row_step = 0, -height-1, 1
					else
						first_row, last_row, row_step = height-1, 0, -1
					end
					if bit_depth == 24 then
						local last_row_item, r, g, b = (width-1)*3
						for y=first_row, last_row, row_step do
							y = 1 + y * row_size
							for x=0, last_row_item, 3 do
								b, g, r = data:byte(y+x, y+x+2)
								data_packed_n = data_packed_n + 1
								data_packed[data_packed_n] = {
									r = r,
									g = g,
									b = b,
									a = 255
								}
							end
						end
					else	-- bit_depth == 32
						local last_row_item, r, g, b, a = (width-1)*4
						for y=first_row, last_row, row_step do
							y = 1 + y * row_size
							for x=0, last_row_item, 4 do
								b, g, r, a = data:byte(y+x, y+x+3)
								data_packed_n = data_packed_n + 1
								data_packed[data_packed_n] = {
									r = r,
									g = g,
									b = b,
									a = a
								}
							end
						end
					end
					return data_packed
				end,
				data_text = function()
					local data_pack, text, text_n = obj.data_packed(), {"{\\bord0\\shad0\\an7\\p1}"}, 1
					local x, y, off_x, chunk_size, color1, color2 = 0, 0, 0
					local i, n = 1, #data_pack
					while i <= n do
						if x == width then
							x = 0
							y = y + 1
							off_x = off_x - width
						end
						chunk_size, color1, text_n = 1, data_pack[i], text_n + 1
						if color1.a == 0 then
							for xx=x+1, width-1 do
								color2 = data_pack[i+(xx-x)]
								if not (color2 and color2.a == 0) then
									break
								end
								chunk_size = chunk_size + 1
							end
							text[text_n] = string.format("{}m %d %d l %d %d", off_x, y, off_x+chunk_size, y+1)
						else
							for xx=x+1, width-1 do
								color2 = data_pack[i+(xx-x)]
								if not (color2 and color1.r == color2.r and color1.g == color2.g and color1.b == color2.b and color1.a == color2.a) then
									break
								end
								chunk_size = chunk_size + 1
							end
							text[text_n] = string.format("{\\c&H%02X%02X%02X&\\1a&H%02X&}m %d %d l %d %d %d %d %d %d",
																	color1.b, color1.g, color1.r, 255-color1.a, off_x, y, off_x+chunk_size, y, off_x+chunk_size, y+1, off_x, y+1)
						end
						i, x = i + chunk_size, x + chunk_size
					end
					return table.concat(text)
				end
			}
			return obj
		end,
		-- Creates font
		create_font = function(family, bold, italic, underline, strikeout, size, xscale, yscale, hspace)
			-- Check arguments
			if type(family) ~= "string" or type(bold) ~= "boolean" or type(italic) ~= "boolean" or type(underline) ~= "boolean" or type(strikeout) ~= "boolean" or type(size) ~= "number" or size <= 0 or
				(xscale ~= nil and type(xscale) ~= "number") or (yscale ~= nil and type(yscale) ~= "number") or (hspace ~= nil and type(hspace) ~= "number") then
				error("expected family, bold, italic, underline, strikeout, size and optional horizontal & vertical scale and intercharacter space", 2)
			end
			-- Set optional arguments (if not already)
			if not xscale then
				xscale = 1
			end
			if not yscale then
				yscale = 1
			end
			if not hspace then
				hspace = 0
			end
			-- Font scale values for increased size & later downscaling to produce floating point coordinates
			local upscale = FONT_PRECISION
			local downscale = 1 / upscale
			-- Body by operation system
			if ffi.os == "Windows" then
				-- Create device context and set light resources deleter
				local resources_deleter
				local dc = ffi.gc(ffi.C.CreateCompatibleDC(nil), function() resources_deleter() end)
				-- Set context coordinates mapping mode
				ffi.C.SetMapMode(dc, ffi.C.MM_TEXT)
				-- Set context backgrounds to transparent
				ffi.C.SetBkMode(dc, ffi.C.TRANSPARENT)
				-- Convert family from utf8 to utf16
				family = utf8_to_utf16(family)
				if ffi.C.wcslen(family) > 31 then
					error("family name to long", 2)
				end
				-- Create font handle
				local font = ffi.C.CreateFontW(
					size * upscale,	-- nHeight
					0,	-- nWidth
					0,	-- nEscapement
					0,	-- nOrientation
					bold and ffi.C.FW_BOLD or ffi.C.FW_NORMAL,	-- fnWeight
					italic and 1 or 0,	-- fdwItalic
					underline and 1 or 0,	--fdwUnderline
					strikeout and 1 or 0,	-- fdwStrikeOut
					ffi.C.DEFAULT_CHARSET,	-- fdwCharSet
					ffi.C.OUT_TT_PRECIS,	-- fdwOutputPrecision
					ffi.C.CLIP_DEFAULT_PRECIS,	-- fdwClipPrecision
					ffi.C.ANTIALIASED_QUALITY,	-- fdwQuality
					ffi.C.DEFAULT_PITCH + ffi.C.FF_DONTCARE,	-- fdwPitchAndFamily
					family
				)
				-- Set new font to device context
				local old_font = ffi.C.SelectObject(dc, font)
				-- Define light resources deleter
				resources_deleter = function()
					ffi.C.SelectObject(dc, old_font)
					ffi.C.DeleteObject(font)
					ffi.C.DeleteDC(dc)
				end
				-- Return font object
				return {
					-- Get font metrics
					metrics = function()
						-- Get font metrics from device context
						local metrics = ffi.new("TEXTMETRICW[1]")
						ffi.C.GetTextMetricsW(dc, metrics)
						return {
							height = metrics[0].tmHeight * downscale * yscale,
							ascent = metrics[0].tmAscent * downscale * yscale,
							descent = metrics[0].tmDescent * downscale * yscale,
							internal_leading = metrics[0].tmInternalLeading * downscale * yscale,
							external_leading = metrics[0].tmExternalLeading * downscale * yscale
						}
					end,
					-- Get text extents
					text_extents = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Get utf16 text
						text = utf8_to_utf16(text)
						local text_len = ffi.C.wcslen(text)
						-- Get text extents with this font
						local size = ffi.new("SIZE[1]")
						ffi.C.GetTextExtentPoint32W(dc, text, text_len, size)
						return {
							width = (size[0].cx * downscale + hspace * text_len) * xscale,
							height = size[0].cy * downscale * yscale
						}
					end,
					-- Converts text to ASS shape
					text_to_shape = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Initialize shape as table
						local shape, shape_n = {}, 0
						-- Get utf16 text
						text = utf8_to_utf16(text)
						local text_len = ffi.C.wcslen(text)
						-- Add path to device context
						if text_len > 8192 then
							error("text too long", 2)
						end
						local char_widths
						if hspace ~= 0 then
							char_widths = ffi.new("INT[?]", text_len)
							local size, space = ffi.new("SIZE[1]"), hspace * upscale
							for i=0, text_len-1 do
								ffi.C.GetTextExtentPoint32W(dc, text+i, 1, size)
								char_widths[i] = size[0].cx + space
							end
						end
						ffi.C.BeginPath(dc)
						ffi.C.ExtTextOutW(dc, 0, 0, 0x0, nil, text, text_len, char_widths)
						ffi.C.EndPath(dc)
						-- Get path data
						local points_n = ffi.C.GetPath(dc, nil, nil, 0)
						if points_n > 0 then
							local points, types = ffi.new("POINT[?]", points_n), ffi.new("BYTE[?]", points_n)
							ffi.C.GetPath(dc, points, types, points_n)
							-- Convert points to shape
							local i, last_type, cur_type, cur_point = 0
							while i < points_n do
								cur_type, cur_point = types[i], points[i]
								if cur_type == ffi.C.PT_MOVETO then
									if last_type ~= ffi.C.PT_MOVETO then
										shape_n = shape_n + 1
										shape[shape_n] = "m"
										last_type = cur_type
									end
									shape[shape_n+1] = roundf(cur_point.x * downscale * xscale)
									shape[shape_n+2] = roundf(cur_point.y * downscale * yscale)
									shape_n = shape_n + 2
									i = i + 1
								elseif cur_type == ffi.C.PT_LINETO or cur_type == (ffi.C.PT_LINETO + ffi.C.PT_CLOSEFIGURE) then
									if last_type ~= ffi.C.PT_LINETO then
										shape_n = shape_n + 1
										shape[shape_n] = "l"
										last_type = cur_type
									end
									shape[shape_n+1] = roundf(cur_point.x * downscale * xscale)
									shape[shape_n+2] = roundf(cur_point.y * downscale * yscale)
									shape_n = shape_n + 2
									i = i + 1
								elseif cur_type == ffi.C.PT_BEZIERTO or cur_type == (ffi.C.PT_BEZIERTO + ffi.C.PT_CLOSEFIGURE) then
									if last_type ~= ffi.C.PT_BEZIERTO then
										shape_n = shape_n + 1
										shape[shape_n] = "b"
										last_type = cur_type
									end
									shape[shape_n+1] = roundf(cur_point.x * downscale * xscale)
									shape[shape_n+2] = roundf(cur_point.y * downscale * yscale)
									shape[shape_n+3] = roundf(points[i+1].x * downscale * xscale)
									shape[shape_n+4] = roundf(points[i+1].y * downscale * yscale)
									shape[shape_n+5] = roundf(points[i+2].x * downscale * xscale)
									shape[shape_n+6] = roundf(points[i+2].y * downscale * yscale)
									shape_n = shape_n + 6
									i = i + 3
								else	-- invalid type (should never happen, but let us be safe)
									i = i + 1
								end
								if cur_type % 2 == 1 then	-- odd = PT_CLOSEFIGURE
									shape_n = shape_n + 1
									shape[shape_n] = "c"
								end
							end
						end
						-- Clear device context path
						ffi.C.AbortPath(dc)
						-- Return shape as string
						return table.concat(shape, " ")
					end
				}
			else	-- Unix
				-- Create surface, context & layout
				local surface = pangocairo.cairo_image_surface_create(ffi.C.CAIRO_FORMAT_A8, 1, 1)
				local context = pangocairo.cairo_create(surface)
				local layout
				layout = ffi.gc(pangocairo.pango_cairo_create_layout(context), function()
					pangocairo.g_object_unref(layout)
					pangocairo.cairo_destroy(context)
					pangocairo.cairo_surface_destroy(surface)
				end)
				-- Set font to layout
				local font_desc = ffi.gc(pangocairo.pango_font_description_new(), pangocairo.pango_font_description_free)
				pangocairo.pango_font_description_set_family(font_desc, family)
				pangocairo.pango_font_description_set_weight(font_desc, bold and ffi.C.PANGO_WEIGHT_BOLD or ffi.C.PANGO_WEIGHT_NORMAL)
				pangocairo.pango_font_description_set_style(font_desc, italic and ffi.C.PANGO_STYLE_ITALIC or ffi.C.PANGO_STYLE_NORMAL)
				pangocairo.pango_font_description_set_absolute_size(font_desc, size * ffi.C.PANGO_SCALE * upscale)
				pangocairo.pango_layout_set_font_description(layout, font_desc)
				local attr = ffi.gc(pangocairo.pango_attr_list_new(), pangocairo.pango_attr_list_unref)
				pangocairo.pango_attr_list_insert(attr, pangocairo.pango_attr_underline_new(underline and ffi.C.PANGO_UNDERLINE_SINGLE or ffi.C.PANGO_UNDERLINE_NONE))
				pangocairo.pango_attr_list_insert(attr, pangocairo.pango_attr_strikethrough_new(strikeout))
				pangocairo.pango_attr_list_insert(attr, pangocairo.pango_attr_letter_spacing_new(hspace * ffi.C.PANGO_SCALE * upscale))
				pangocairo.pango_layout_set_attributes(layout, attr)
				-- Scale factor for resulting font data
				local fonthack_scale
				if LIBASS_FONTHACK then
					local metrics = ffi.gc(pangocairo.pango_context_get_metrics(pangocairo.pango_layout_get_context(layout), pangocairo.pango_layout_get_font_description(layout), nil), pangocairo.pango_font_metrics_unref)
					fonthack_scale = size / ((pangocairo.pango_font_metrics_get_ascent(metrics) + pangocairo.pango_font_metrics_get_descent(metrics)) / ffi.C.PANGO_SCALE * downscale)
				else
					fonthack_scale = 1
				end
				-- Return font object
				return {
					-- Get font metrics
					metrics = function()
						local metrics = ffi.gc(pangocairo.pango_context_get_metrics(pangocairo.pango_layout_get_context(layout), pangocairo.pango_layout_get_font_description(layout), nil), pangocairo.pango_font_metrics_unref)
						local ascent, descent = pangocairo.pango_font_metrics_get_ascent(metrics) / ffi.C.PANGO_SCALE * downscale,
												pangocairo.pango_font_metrics_get_descent(metrics) / ffi.C.PANGO_SCALE * downscale
						return {
							height = (ascent + descent) * yscale * fonthack_scale,
							ascent = ascent * yscale * fonthack_scale,
							descent = descent * yscale * fonthack_scale,
							internal_leading = 0,
							external_leading = pangocairo.pango_layout_get_spacing(layout) / ffi.C.PANGO_SCALE * downscale * yscale * fonthack_scale
						}
					end,
					-- Get text extents
					text_extents = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Set text to layout
						pangocairo.pango_layout_set_text(layout, text, -1)
						-- Get text extents with this font
						local rect = ffi.new("PangoRectangle[1]")
						pangocairo.pango_layout_get_pixel_extents(layout, nil, rect)
						return {
							width = rect[0].width * downscale * xscale * fonthack_scale,
							height = rect[0].height * downscale * yscale * fonthack_scale
						}
					end,
					-- Converts text to ASS shape
					text_to_shape = function(text)
						-- Check argument
						if type(text) ~= "string" then
							error("text expected", 2)
						end
						-- Set text path to layout
						pangocairo.cairo_save(context)
						pangocairo.cairo_scale(context, downscale * xscale * fonthack_scale, downscale * yscale * fonthack_scale)
						pangocairo.pango_layout_set_text(layout, text, -1)
						pangocairo.pango_cairo_layout_path(context, layout)
						pangocairo.cairo_restore(context)
						-- Initialize shape as table
						local shape, shape_n = {}, 0
						-- Convert path to shape
						local path = ffi.gc(pangocairo.cairo_copy_path(context), pangocairo.cairo_path_destroy)
						if(path[0].status == ffi.C.CAIRO_STATUS_SUCCESS) then
							local i, cur_type, last_type = 0
							while(i < path[0].num_data) do
								cur_type = path[0].data[i].header.type
								if cur_type == ffi.C.CAIRO_PATH_MOVE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "m"
									end
									shape[shape_n+1] = roundf(path[0].data[i+1].point.x)
									shape[shape_n+2] = roundf(path[0].data[i+1].point.y)
									shape_n = shape_n + 2
								elseif cur_type == ffi.C.CAIRO_PATH_LINE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "l"
									end
									shape[shape_n+1] = roundf(path[0].data[i+1].point.x)
									shape[shape_n+2] = roundf(path[0].data[i+1].point.y)
									shape_n = shape_n + 2
								elseif cur_type == ffi.C.CAIRO_PATH_CURVE_TO then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "b"
									end
									shape[shape_n+1] = roundf(path[0].data[i+1].point.x)
									shape[shape_n+2] = roundf(path[0].data[i+1].point.y)
									shape[shape_n+3] = roundf(path[0].data[i+2].point.x)
									shape[shape_n+4] = roundf(path[0].data[i+2].point.y)
									shape[shape_n+5] = roundf(path[0].data[i+3].point.x)
									shape[shape_n+6] = roundf(path[0].data[i+3].point.y)
									shape_n = shape_n + 6
								elseif cur_type == ffi.C.CAIRO_PATH_CLOSE_PATH then
									if cur_type ~= last_type then
										shape_n = shape_n + 1
										shape[shape_n] = "c"
									end
								end
								last_type = cur_type
								i = i + path[0].data[i].header.length
							end
						end
						pangocairo.cairo_new_path(context)
						return table.concat(shape, " ")
					end
				}
			end
		end,
		-- Lists available system fonts
		list_fonts = function(with_filenames)
			-- Check argument
			if with_filenames ~= nil and type(with_filenames) ~= "boolean" then
				error("optional boolean expected", 2)
			end
			-- Output fonts buffer
			local fonts = {n = 0}
			-- Body by operation system
			if ffi.os == "Windows" then
				-- Enumerate font families (of all charsets)
				local plogfont = ffi.new("LOGFONTW[1]")
				plogfont[0].lfCharSet = ffi.C.DEFAULT_CHARSET
				plogfont[0].lfFaceName[0] = 0	-- Empty string
				plogfont[0].lfPitchAndFamily = ffi.C.DEFAULT_PITCH + ffi.C.FF_DONTCARE
				local fontname, style, font
				ffi.C.EnumFontFamiliesExW(ffi.gc(ffi.C.CreateCompatibleDC(nil), ffi.C.DeleteDC), plogfont, function(penumlogfont, _, fonttype, _)
					-- Skip different font charsets
					fontname, style = utf16_to_utf8(penumlogfont[0].elfLogFont.lfFaceName), utf16_to_utf8(penumlogfont[0].elfStyle)
					for i=1, fonts.n do
						font = fonts[i]
						if font.name == fontname and font.style == style then
							goto font_found
						end
					end
					-- Add font entry
					fonts.n = fonts.n + 1
					fonts[fonts.n] = {
						name = fontname,
						longname = utf16_to_utf8(penumlogfont[0].elfFullName),
						style = style,
						type = fonttype == ffi.C.FONTTYPE_RASTER and "Raster" or fonttype == ffi.C.FONTTYPE_DEVICE and "Device" or fonttype == ffi.C.FONTTYPE_TRUETYPE and "TrueType" or "Unknown",
					}
					::font_found::
					-- Continue enumeration (till end)
					return 1
				end, 0, 0)
				-- Files to fonts?
				if with_filenames then
					-- Adds filename to fitting font
					local function file_to_font(fontname, fontfile)
						for i=1, fonts.n do
							font = fonts[i]
							if fontname == font.name:gsub("^@", "", 1) or fontname == string.format("%s %s", font.name:gsub("^@", "", 1), font.style) or fontname == font.longname:gsub("^@", "", 1) then
								font.file = fontfile
							end
						end
					end
					-- Search registry for font files
					local pregkey, fontfile = ffi.new("HKEY[1]")
					if advapi.RegOpenKeyExA(ffi.cast("HKEY", ffi.C.HKEY_LOCAL_MACHINE), "SOFTWARE\\Microsoft\\Windows NT\\CurrentVersion\\Fonts", 0, ffi.C.KEY_READ, pregkey) == ffi.C.ERROR_SUCCESS then
						local regkey = ffi.gc(pregkey[0], advapi.RegCloseKey)
						local value_index, value_name, pvalue_name_size, value_data, pvalue_data_size = 0, ffi.new("wchar_t[16383]"), ffi.new("DWORD[1]"), ffi.new("BYTE[65536]"), ffi.new("DWORD[1]")
						while true do
							pvalue_name_size[0], pvalue_data_size[0] = ffi.sizeof(value_name) / ffi.sizeof("wchar_t"), ffi.sizeof(value_data)
							if advapi.RegEnumValueW(regkey, value_index, value_name, pvalue_name_size, nil, nil, value_data, pvalue_data_size) ~= ffi.C.ERROR_SUCCESS then
								break
							else
								value_index = value_index + 1
							end
							fontname = utf16_to_utf8(value_name):gsub("(.*) %(.-%)$", "%1", 1)
							fontfile = utf16_to_utf8(ffi.cast("wchar_t*", value_data))
							file_to_font(fontname, fontfile)
							if fontname:find(" & ") then
								for fontname in fontname:gmatch("(.-) & ") do
									file_to_font(fontname, fontfile)
								end
								file_to_font(fontname:match(".* & (.-)$"), fontfile)
							end
						end
					end
				end
			else	-- Unix
				-- Get fonts list from fontconfig
				local fontset = ffi.gc(fontconfig.FcFontList(fontconfig.FcInitLoadConfigAndFonts(),
															ffi.gc(fontconfig.FcPatternCreate(), fontconfig.FcPatternDestroy),
															ffi.gc(fontconfig.FcObjectSetBuild("family", "fullname", "style", "outline", with_filenames and "file" or nil, nil), fontconfig.FcObjectSetDestroy)),
										fontconfig.FcFontSetDestroy)
				-- Enumerate fonts
				local font, family, fullname, style, outline, file
				local cstr, cbool = ffi.new("FcChar8*[1]"), ffi.new("FcBool[1]")
				for i=0, fontset[0].nfont-1 do
					-- Get font informations
					font = fontset[0].fonts[i]
					family, fullname, style, outline, file = nil
					if fontconfig.FcPatternGetString(font, "family", 0, cstr) == ffi.C.FcResultMatch then
						family = ffi.string(cstr[0])
					end
					if fontconfig.FcPatternGetString(font, "fullname", 0, cstr) == ffi.C.FcResultMatch then
						fullname = ffi.string(cstr[0])
					end
					if fontconfig.FcPatternGetString(font, "style", 0, cstr) == ffi.C.FcResultMatch then
						style = ffi.string(cstr[0])
					end
					if fontconfig.FcPatternGetBool(font, "outline", 0, cbool) == ffi.C.FcResultMatch then
						outline = cbool[0]
					end
					if fontconfig.FcPatternGetString(font, "file", 0, cstr) == ffi.C.FcResultMatch then
						file = ffi.string(cstr[0])
					end
					-- Add font entry
					if family and fullname and style and outline then
						fonts.n = fonts.n + 1
						fonts[fonts.n] = {
							name = family,
							longname = fullname,
							style = style,
							type = outline == 0 and "Raster" or "Outline",
							file = file
						}
					end
				end
			end
			-- Order fonts by name & style
			table.sort(fonts, function(font1, font2)
				if font1.name == font2.name then
					return font1.style < font2.style
				else
					return font1.name < font2.name
				end
			end)
			-- Return collected fonts
			return fonts
		end
	}
}

-- Return library to script loader
return Yutils