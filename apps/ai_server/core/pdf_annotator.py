import fitz
import json
import logging

def hex_to_rgb(flutter_color_int):
    # Flutter color is ARGB, e.g. 4294198070 -> 0xFFFF5256
    # Extract RGB
    b = flutter_color_int & 255
    g = (flutter_color_int >> 8) & 255
    r = (flutter_color_int >> 16) & 255
    a = (flutter_color_int >> 24) & 255
    
    return (r / 255.0, g / 255.0, b / 255.0), (a / 255.0)

def annotate_pdf(original_pdf_path: str, output_pdf_path: str, annotations_json_str: str, page_widths_json: str):
    """
    annotations_json_str format:
    [
      {
        "page": 1,
        "type": "pen",
        "geometry": "{\"points\":[{\"x\":10,\"y\":20}],\"color\":4294198070,\"size\":5.0,\"tool\":0}"
      }
    ]
    
    page_widths_json format:
    { "1": {"width": 800, "height": 1200} }
    # To scale flutter coordinates to PDF coordinates
    """
    try:
        doc = fitz.open(original_pdf_path)
        annotations = json.loads(annotations_json_str)
        page_metrics = json.loads(page_widths_json)
        
        for ann in annotations:
            page_num = ann.get("page")
            if page_num < 1 or page_num > len(doc):
                continue
                
            page = doc[page_num - 1]
            geom = json.loads(ann.get("geometry", "{}"))
            
            points = geom.get("points", [])
            color_int = geom.get("color", 4278190080)
            size = geom.get("size", 2.0)
            tool_idx = geom.get("tool", 0)
            
            if not points:
                continue
                
            rgb, alpha = hex_to_rgb(color_int)
            
            # Coordinate scaling
            metrics = page_metrics.get(str(page_num), {"width": page.rect.width, "height": page.rect.height})
            scale_x = page.rect.width / metrics["width"]
            scale_y = page.rect.height / metrics["height"]
            
            fitz_points = [fitz.Point(p["x"] * scale_x, p["y"] * scale_y) for p in points]
            
            if tool_idx in [0, 1]: # Pen or Highlighter
                if len(fitz_points) == 1:
                    page.draw_circle(fitz_points[0], size / 2, color=rgb, fill=rgb, fill_opacity=alpha, stroke_opacity=alpha)
                else:
                    page.draw_polyline(fitz_points, color=rgb, width=size, stroke_opacity=alpha)
            
            elif tool_idx == 5: # Rectangle
                if len(fitz_points) >= 2:
                    p1 = fitz_points[0]
                    p2 = fitz_points[-1]
                    rect = fitz.Rect(p1, p2)
                    page.draw_rect(rect, color=rgb, width=size, stroke_opacity=alpha)
                    
            elif tool_idx == 6: # Circle
                if len(fitz_points) >= 2:
                    p1 = fitz_points[0]
                    p2 = fitz_points[-1]
                    center = fitz.Point((p1.x + p2.x)/2, (p1.y + p2.y)/2)
                    radius = abs(p1.distance_to(p2)) / 2
                    page.draw_circle(center, radius, color=rgb, width=size, stroke_opacity=alpha)
            
            elif tool_idx == 7: # Line
                if len(fitz_points) >= 2:
                    page.draw_line(fitz_points[0], fitz_points[-1], color=rgb, width=size, stroke_opacity=alpha)
            
            elif tool_idx == 8: # Arrow
                if len(fitz_points) >= 2:
                    # PyMuPDF doesn't have draw_arrow built-in, but we can draw a line and add a polygon
                    # A simpler approach: use draw_line and we'll ignore the arrow head for now to keep it robust
                    # or draw a small triangle
                    page.draw_line(fitz_points[0], fitz_points[-1], color=rgb, width=size, stroke_opacity=alpha)

        doc.save(output_pdf_path)
        doc.close()
        return True, "Success"
    except Exception as e:
        logging.error(f"Error annotating PDF: {e}")
        return False, str(e)
