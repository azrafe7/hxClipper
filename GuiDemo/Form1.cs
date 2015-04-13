//#define UsePolyTree

using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Reflection;
using System.Linq;
using System.Windows.Forms;
using System.Globalization;
using hxClipper;

// NOTE(az): try to avoid "dynamic" and find a suitable way to mimic typedefs fom haxe

namespace WindowsFormsApplication1
{
  using Polygon = Array<object>; // Array<IntPoint>;
  using Polygons = Array<object>; // Array<Array<IntPoint>>;

  public partial class Form1 : Form
  {
    private Bitmap mybitmap;
    private Polygons subjects = new Polygons();
    private Polygons clips = new Polygons();
    private Polygons solution = new Polygons();
#if UsePolyTree
    private PolyTree solutionTree = new PolyTree();
#endif
    //Here we are scaling all coordinates up by 100 when they're passed to Clipper 
    //via Polygon (or Polygons) objects because Clipper no longer accepts floating  
    //point values. Likewise when Clipper returns a solution in a Polygons object, 
    //we need to scale down these returned values by the same amount before displaying.
    private float scale = 10; //or 1 or 10 or 10000 etc for lesser or greater precision.

    //------------------------------------------------------------------------------
    //---------------------------------------------------------------------

    //a very simple class that builds an SVG file with any number of 
    //polygons of the specified formats ...
    class SVGBuilder
    {
      public class StyleInfo
      {
        public PolyFillType pft;
        public Color brushClr;
        public Color penClr;
        public double penWidth;
        public int[] dashArray;
        public Boolean showCoords;
        public StyleInfo Clone()
        {
          StyleInfo si = new StyleInfo();
          si.pft = this.pft;
          si.brushClr = this.brushClr;
          si.dashArray = this.dashArray;
          si.penClr = this.penClr;
          si.penWidth = this.penWidth;
          si.showCoords = this.showCoords;
          return si;
        }
        public StyleInfo()
        {
          pft = PolyFillType.PFT_NON_ZERO;
          brushClr = Color.AntiqueWhite;
          dashArray = null;
          penClr = Color.Black;
          penWidth = 0.8;
          showCoords = false;
        }
      }

      public class PolyInfo
      {
        public Polygons polygons;
        public StyleInfo si;
      }

      public StyleInfo style;
      private List<PolyInfo> PolyInfoList;
      const string svg_header = "<?xml version=\"1.0\" standalone=\"no\"?>\n" +
        "<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.0//EN\"\n" +
        "\"http://www.w3.org/TR/2001/REC-SVG-20010904/DTD/svg10.dtd\">\n\n" +
        "<svg width=\"{0}px\" height=\"{1}px\" viewBox=\"0 0 {2} {3}\" " +
        "version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\">\n\n";
      const string svg_path_format = "\"\n style=\"fill:{0};" +
          " fill-opacity:{1:f2}; fill-rule:{2}; stroke:{3};" +
          " stroke-opacity:{4:f2}; stroke-width:{5:f2};\"/>\n\n";

      public SVGBuilder()
      {
        PolyInfoList = new List<PolyInfo>();
        style = new StyleInfo();
      }

      public void AddPolygons(Polygons poly)
      {
        if (poly.length == 0) return;
        PolyInfo pi = new PolyInfo();
        pi.polygons = poly;
        pi.si = style.Clone();
        PolyInfoList.Add(pi);
      }

      public Boolean SaveToFile(string filename, double scale = 1.0, int margin = 10)
      {
        if (scale == 0) scale = 1.0;
        if (margin < 0) margin = 0;

        //calculate the bounding rect ...
        int i = 0, j = 0;
        dynamic dyn_polyInfoList = PolyInfoList;
        while (i < PolyInfoList.Count)
        {
          j = 0;
          while (j < PolyInfoList[i].polygons.length &&
              dyn_polyInfoList[i].polygons[j].length == 0) j++;
          if (j < PolyInfoList[i].polygons.length) break;
          i++;
        }
        if (i == dyn_polyInfoList.Count) return false;
        IntRect rec = new IntRect(haxe.lang.EmptyObject.EMPTY);
        rec.left = dyn_polyInfoList[i].polygons[j][0].x;
        rec.right = rec.left;
        rec.top = dyn_polyInfoList[0].polygons[j][0].y;
        rec.bottom = rec.top;

        for (; i < PolyInfoList.Count; i++)
        {
            for (j = 0; j < PolyInfoList[i].polygons.length; j++)
            {
                Polygon pg = (Polygon)PolyInfoList[i].polygons[j];
                for (int k=0; k<pg.length; k++)
                {
                    IntPoint pt = (IntPoint)pg[k];
                    if (pt.x < rec.left) rec.left = pt.x;
                    else if (pt.x > rec.right) rec.right = pt.x;
                    if (pt.y < rec.top) rec.top = pt.y;
                    else if (pt.y > rec.bottom) rec.bottom = pt.y;
                }
            }
        }

        rec.left = (int)(rec.left * scale);
        rec.top = (int)(rec.top * scale);
        rec.right = (int)(rec.right * scale);
        rec.bottom = (int)(rec.bottom * scale);
        Int64 offsetX = -rec.left + margin;
        Int64 offsetY = -rec.top + margin;

        using (StreamWriter writer = new StreamWriter(filename))
        {
          writer.Write(svg_header,
              (rec.right - rec.left) + margin * 2,
              (rec.bottom - rec.top) + margin * 2,
              (rec.right - rec.left) + margin * 2,
              (rec.bottom - rec.top) + margin * 2);

          foreach (PolyInfo pi in PolyInfoList)
          {
            writer.Write(" <path d=\"");
            for (j = 0; j < pi.polygons.length; j++)
            {
              dynamic dyn_p = pi.polygons[j];
              writer.Write(String.Format(NumberFormatInfo.InvariantInfo, " M {0:f2} {1:f2}",
                  (double)((double)dyn_p[0].x * scale + offsetX),
                  (double)((double)dyn_p[0].y * scale + offsetY)));
              for (int k = 1; k < dyn_p.length; k++)
              {
                writer.Write(String.Format(NumberFormatInfo.InvariantInfo, " L {0:f2} {1:f2}",
                (double)((double)dyn_p[k].x * scale + offsetX),
                (double)((double)dyn_p[k].y * scale + offsetY)));
              }
              writer.Write(" z");
            }

            writer.Write(String.Format(NumberFormatInfo.InvariantInfo, svg_path_format,
            ColorTranslator.ToHtml(pi.si.brushClr),
            (float)pi.si.brushClr.A / 255,
            (pi.si.pft == PolyFillType.PFT_EVEN_ODD ? "evenodd" : "nonzero"),
            ColorTranslator.ToHtml(pi.si.penClr),
            (float)pi.si.penClr.A / 255,
            pi.si.penWidth));

            if (pi.si.showCoords)
            {
              writer.Write("<g font-family=\"Verdana\" font-size=\"11\" fill=\"black\">\n\n");
              for (j=0; j<pi.polygons.length; j++)
              {
                Polygon p = (Polygon)pi.polygons[j];
                for (int k = 0; k<p.length; k++)
                {
                  IntPoint pt = (IntPoint)p[k];
                  int x = pt.x;
                  int y = pt.y;
                  writer.Write(String.Format(
                      "<text x=\"{0}\" y=\"{1}\">{2},{3}</text>\n",
                      (int)(x * scale + offsetX), (int)(y * scale + offsetY), x, y));

                }
                writer.Write("\n");
              }
              writer.Write("</g>\n");
            }
          }
          writer.Write("</svg>\n");
        }
        return true;
      }
    }

    //------------------------------------------------------------------------------
    //------------------------------------------------------------------------------

    static private PointF[] PolygonToPointFArray(Polygon pg, float scale)
    {
      PointF[] result = new PointF[pg.length];
      dynamic dyn_pg = pg;
      for (int i = 0; i < pg.length; ++i)
      {
        result[i].X = (float)dyn_pg[i].x / scale;
        result[i].Y = (float)dyn_pg[i].y / scale;
      }
      return result;
    }

    public Form1()
    {
      InitializeComponent();
      this.MouseWheel += new MouseEventHandler(Form1_MouseWheel);
      mybitmap = new Bitmap(
        pictureBox1.ClientRectangle.Width,
        pictureBox1.ClientRectangle.Height,
        PixelFormat.Format32bppArgb);
    }
    //---------------------------------------------------------------------

    private void Form1_MouseWheel(object sender, MouseEventArgs e)
    {
      if (e.Delta > 0 && nudOffset.Value < 10) nudOffset.Value += (decimal)0.5;
      else if (e.Delta < 0 && nudOffset.Value > -10) nudOffset.Value -= (decimal)0.5;
    }
    //---------------------------------------------------------------------

    private void bRefresh_Click(object sender, EventArgs e)
    {
      DrawBitmap();
    }
    //---------------------------------------------------------------------

    private void GenerateAustPlusRandomEllipses(int count)
    {
        InternalTools.clear(subjects);
      //load map of Australia from resource ...
      Assembly _assembly = Assembly.GetExecutingAssembly();
      using (BinaryReader polyStream = new BinaryReader(_assembly.GetManifestResourceStream("GuiDemo.aust.bin")))
      {
        int polyCnt = polyStream.ReadInt32();
        for (int i = 0; i < polyCnt; ++i)
        {
          int vertCnt = polyStream.ReadInt32();
          Polygon pg = new Polygon();
          for (int j = 0; j < vertCnt; ++j)
          {
            float x = polyStream.ReadSingle() * scale;
            float y = polyStream.ReadSingle() * scale;
            pg.push(new IntPoint(new haxe.lang.Null<int>((int)x, true), new haxe.lang.Null<int>((int)y, true)));
          }
          subjects.push(pg);
        }
      }
      InternalTools.clear(clips);
      Random rand = new Random();
      using (GraphicsPath path = new GraphicsPath())
      {
        const int ellipse_size = 100, margin = 10;
        for (int i = 0; i < count; ++i)
        {
          int w = pictureBox1.ClientRectangle.Width - ellipse_size - margin * 2;
          int h = pictureBox1.ClientRectangle.Height - ellipse_size - margin * 2 - statusStrip1.Height;

          int x = rand.Next(w) + margin;
          int y = rand.Next(h) + margin;
          int size = rand.Next(ellipse_size - 20) + 20;
          path.Reset();
          path.AddEllipse(x, y, size, size);
          path.Flatten();
          Polygon clip = new Polygon();
          foreach (PointF p in path.PathPoints)
            clip.push(new IntPoint(new haxe.lang.Null<int>((int)(p.X * scale), true), new haxe.lang.Null<int>((int)(p.Y * scale), true)));
          clips.push(clip);
        }
      }
    }
    //---------------------------------------------------------------------

    private IntPoint GenerateRandomPoint(int l, int t, int r, int b, Random rand)
    {
      int Q = 10;
      return new IntPoint(
        new haxe.lang.Null<int>((int)((rand.Next(r / Q) * Q + l + 10) * scale), true),
        new haxe.lang.Null<int>((int)((rand.Next(b / Q) * Q + t + 10) * scale), true));
    }
    //---------------------------------------------------------------------

    private void GenerateRandomPolygon(int count)
    {
      int Q = 10;
      Random rand = new Random();
      int l = 10;
      int t = 10;
      int r = (pictureBox1.ClientRectangle.Width - 20) / Q * Q;
      int b = (pictureBox1.ClientRectangle.Height - 20) / Q * Q;

      InternalTools.clear(subjects);
      InternalTools.clear(clips);

      Polygon subj = new Polygon();
      for (int i = 0; i < count; ++i)
        subj.push(GenerateRandomPoint(l, t, r, b, rand));
      subjects.push(subj);

      Polygon clip = new Polygon();
      for (int i = 0; i < count; ++i)
        clip.push(GenerateRandomPoint(l, t, r, b, rand));
      clips.push(clip);
    }
    //---------------------------------------------------------------------

    ClipType GetClipType()
    {
      if (rbIntersect.Checked) return ClipType.CT_INTERSECTION;
      if (rbUnion.Checked) return ClipType.CT_UNION;
      if (rbDifference.Checked) return ClipType.CT_DIFFERENCE;
      else return ClipType.CT_XOR;
    }
    //---------------------------------------------------------------------

    PolyFillType GetPolyFillType()
    {
      if (rbNonZero.Checked) return PolyFillType.PFT_NON_ZERO;
      else return PolyFillType.PFT_EVEN_ODD;
    }
    //---------------------------------------------------------------------

    bool LoadFromFile(string filename, Polygons ppg, double scale = 0,
      int xOffset = 0, int yOffset = 0)
    {
      double scaling = System.Math.Pow(10, scale);
      InternalTools.clear(ppg);
      if (!File.Exists(filename)) return false;
      using (StreamReader sr = new StreamReader(filename))
      {
        string line;
        if ((line = sr.ReadLine()) == null)
          return false;
        int polyCnt, vertCnt;
        if (!Int32.TryParse(line, out polyCnt) || polyCnt < 0)
          return false;
        //ppg.Capacity = polyCnt;
        for (int i = 0; i < polyCnt; i++)
        {
          if ((line = sr.ReadLine()) == null)
            return false;
          if (!Int32.TryParse(line, out vertCnt) || vertCnt < 0)
            return false;
          Polygon pg = new Polygon();
          ppg.push(pg);
          for (int j = 0; j < vertCnt; j++)
          {
            double x, y;
            if ((line = sr.ReadLine()) == null)
              return false;
            char[] delimiters = new char[] { ',', ' ' };
            string[] vals = line.Split(delimiters);
            if (vals.Length < 2)
              return false;
            if (!double.TryParse(vals[0], out x))
              return false;
            if (!double.TryParse(vals[1], out y))
              if (vals.Length < 2 || !double.TryParse(vals[2], out y))
                return false;
            x = x * scaling + xOffset;
            y = y * scaling + yOffset;
            pg.push(new IntPoint(new haxe.lang.Null<int>((int)System.Math.Round(x), true), new haxe.lang.Null<int>((int)System.Math.Round(y), true)));
          }
        }
      }
      return true;
    }
    //------------------------------------------------------------------------------

    void SaveToFile(string filename, Polygons ppg, int scale = 0)
    {
      double scaling = System.Math.Pow(10, scale);
      using (StreamWriter writer = new StreamWriter(filename))
      {
        writer.Write("{0}\n", ppg.length);
        for (int i=0; i<ppg.length; i++)
        {
          Polygon pg = (Polygon) ppg[i];
          writer.Write("{0}\n", pg.length);
          for (int j=0; j<pg.length; j++) {
            IntPoint ip = (IntPoint)pg[j];
            writer.Write("{0:0.0000}, {1:0.0000}\n", ip.x / scaling, ip.y / scaling);
          }
        }
      }
    }
    //---------------------------------------------------------------------------

    private void DrawBitmap(bool justClip = false)
    {
      Cursor.Current = Cursors.WaitCursor;
      try
      {
        if (!justClip)
        {
          if (rbTest2.Checked)
            GenerateAustPlusRandomEllipses((int)nudCount.Value);
          else
            GenerateRandomPolygon((int)nudCount.Value);
        }
        using (Graphics newgraphic = Graphics.FromImage(mybitmap))
        using (GraphicsPath path = new GraphicsPath())
        {
          newgraphic.SmoothingMode = SmoothingMode.AntiAlias;
          newgraphic.Clear(Color.White);
          if (rbNonZero.Checked)
            path.FillMode = FillMode.Winding;

          //draw subjects ...
          for (int i = 0; i < subjects.length; i++ )
          {
              Polygon pg = (Polygon)subjects[i];
              PointF[] pts = PolygonToPointFArray(pg, scale);
              path.AddPolygon(pts);
              pts = null;
          }
          using (Pen myPen = new Pen(Color.FromArgb(196, 0xC3, 0xC9, 0xCF), (float)0.6))
          using (SolidBrush myBrush = new SolidBrush(Color.FromArgb(127, 0xDD, 0xDD, 0xF0)))
          {
            newgraphic.FillPath(myBrush, path);
            newgraphic.DrawPath(myPen, path);
            path.Reset();

            //draw clips ...
            if (rbNonZero.Checked)
              path.FillMode = FillMode.Winding;
            for (int i=0; i< clips.length; i++)
            {
              Polygon pg = (Polygon) clips[i];
              PointF[] pts = PolygonToPointFArray(pg, scale);
              path.AddPolygon(pts);
              pts = null;
            }
            myPen.Color = Color.FromArgb(196, 0xF9, 0xBE, 0xA6);
            myBrush.Color = Color.FromArgb(127, 0xFF, 0xE0, 0xE0);
            newgraphic.FillPath(myBrush, path);
            newgraphic.DrawPath(myPen, path);

            //do the clipping ...
            if ((clips.length > 0 || subjects.length > 0) && !rbNone.Checked)
            {
              Polygons solution2 = new Polygons();
              Clipper c = new Clipper(new haxe.lang.Null<int>(0, false));
              c.addPaths(subjects, PolyType.PT_SUBJECT, true);
              c.addPaths(clips, PolyType.PT_CLIP, true);
              InternalTools.clear(solution);
#if UsePolyTree
              bool succeeded = c.executePolyTree(GetClipType(), solutionTree, GetPolyFillType(), GetPolyFillType());
              //nb: we aren't doing anything useful here with solutionTree except to show
              //that it works. Convert PolyTree back to Polygons structure ...
              solution = Clipper.polyTreeToPaths(solutionTree);
#else
              bool succeeded = c.executePaths(GetClipType(), solution, GetPolyFillType(), GetPolyFillType());
#endif
              if (succeeded)
              {
                //SaveToFile("solution", solution);
                myBrush.Color = Color.Black;
                path.Reset();

                //It really shouldn't matter what FillMode is used for solution
                //polygons because none of the solution polygons overlap. 
                //However, FillMode.Winding will show any orientation errors where 
                //holes will be stroked (outlined) correctly but filled incorrectly  ...
                path.FillMode = FillMode.Winding;

                //or for something fancy ...

                if (nudOffset.Value != 0)
                {
                  ClipperOffset co = new ClipperOffset(new haxe.lang.Null<double>(0.0, false), new haxe.lang.Null<double>(0.0, false));
                  co.addPaths(solution, JoinType.JT_ROUND, EndType.ET_CLOSED_POLYGON);
                  co.executePaths(solution2, (double)nudOffset.Value * scale);
                }
                else
                  solution2 = solution2.concat(solution);// Polygons(solution);

                for (int i = 0; i < solution2.length; i++)
                {
                    Polygon pg = (Polygon)solution2[i];
                    PointF[] pts = PolygonToPointFArray(pg, scale);
                    if (pts.Count() > 2)
                        path.AddPolygon(pts);
                    pts = null;
                }
                myBrush.Color = Color.FromArgb(127, 0x66, 0xEF, 0x7F);
                myPen.Color = Color.FromArgb(255, 0, 0x33, 0);
                myPen.Width = 1.0f;
                newgraphic.FillPath(myBrush, path);
                newgraphic.DrawPath(myPen, path);

                //now do some fancy testing ...
                using (Font f = new Font("Arial", 8))
                using (SolidBrush b = new SolidBrush(Color.Navy))
                {
                  double subj_area = 0, clip_area = 0, int_area = 0, union_area = 0;
                  c.clear();
                  c.addPaths(subjects, PolyType.PT_SUBJECT, true);
                  c.executePaths(ClipType.CT_UNION, solution2, GetPolyFillType(), GetPolyFillType());
                  for (int i = 0; i < solution2.length; i++)
                  {
                      Polygon pg = (Polygon)solution2[i];
                      subj_area += Clipper.area(pg);
                  }
                  c.clear();
                  c.addPaths(clips, PolyType.PT_CLIP, true);
                  c.executePaths(ClipType.CT_UNION, solution2, GetPolyFillType(), GetPolyFillType());
                  for (int i = 0; i < solution2.length; i++)
                  {
                      Polygon pg = (Polygon)solution2[i];
                      clip_area += Clipper.area(pg);
                  }
                  c.addPaths(subjects, PolyType.PT_SUBJECT, true);
                  c.executePaths(ClipType.CT_INTERSECTION, solution2, GetPolyFillType(), GetPolyFillType());
                  for (int i = 0; i < solution2.length; i++)
                  {
                      Polygon pg = (Polygon)solution2[i];
                      int_area += Clipper.area(pg);
                  }
                  c.executePaths(ClipType.CT_UNION, solution2, GetPolyFillType(), GetPolyFillType());
                  for (int i = 0; i < solution2.length; i++)
                  {
                      Polygon pg = (Polygon)solution2[i];
                      union_area += Clipper.area(pg);
                  }

                  using (StringFormat lftStringFormat = new StringFormat())
                  using (StringFormat rtStringFormat = new StringFormat())
                  {
                    lftStringFormat.Alignment = StringAlignment.Near;
                    lftStringFormat.LineAlignment = StringAlignment.Near;
                    rtStringFormat.Alignment = StringAlignment.Far;
                    rtStringFormat.LineAlignment = StringAlignment.Near;
                    Rectangle rec = new Rectangle(pictureBox1.ClientSize.Width - 108,
                                     pictureBox1.ClientSize.Height - 116, 104, 106);
                    newgraphic.FillRectangle(new SolidBrush(Color.FromArgb(196, Color.WhiteSmoke)), rec);
                    newgraphic.DrawRectangle(myPen, rec);
                    rec.Inflate(new Size(-2, 0));
                    newgraphic.DrawString("Areas", f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 14));
                    newgraphic.DrawString("subj: ", f, b, rec, lftStringFormat);
                    newgraphic.DrawString((subj_area / 100000).ToString("0,0"), f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 12));
                    newgraphic.DrawString("clip: ", f, b, rec, lftStringFormat);
                    newgraphic.DrawString((clip_area / 100000).ToString("0,0"), f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 12));
                    newgraphic.DrawString("intersect: ", f, b, rec, lftStringFormat);
                    newgraphic.DrawString((int_area / 100000).ToString("0,0"), f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 12));
                    newgraphic.DrawString("---------", f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 10));
                    newgraphic.DrawString("s + c - i: ", f, b, rec, lftStringFormat);
                    newgraphic.DrawString(((subj_area + clip_area - int_area) / 100000).ToString("0,0"), f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 10));
                    newgraphic.DrawString("---------", f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 10));
                    newgraphic.DrawString("union: ", f, b, rec, lftStringFormat);
                    newgraphic.DrawString((union_area / 100000).ToString("0,0"), f, b, rec, rtStringFormat);
                    rec.Offset(new Point(0, 10));
                    newgraphic.DrawString("---------", f, b, rec, rtStringFormat);
                  }
                }
              } //end if succeeded
            } //end if something to clip
            pictureBox1.Image = mybitmap;
          }
        }
      }
      finally
      {
        Cursor.Current = Cursors.Default;
      }
    }
    //---------------------------------------------------------------------

    private void Form1_Load(object sender, EventArgs e)
    {
      toolStripStatusLabel1.Text =
          "Tip: Use the mouse-wheel (or +,-,0) to adjust the offset of the solution polygons.";
      DrawBitmap();
    }
    //---------------------------------------------------------------------

    private void bClose_Click(object sender, EventArgs e)
    {
      Close();
    }
    //---------------------------------------------------------------------

    private void Form1_Resize(object sender, EventArgs e)
    {
      if (pictureBox1.ClientRectangle.Width == 0 ||
          pictureBox1.ClientRectangle.Height == 0) return;
      if (mybitmap != null)
        mybitmap.Dispose();
      mybitmap = new Bitmap(
          pictureBox1.ClientRectangle.Width,
          pictureBox1.ClientRectangle.Height,
          PixelFormat.Format32bppArgb);
      pictureBox1.Image = mybitmap;
      DrawBitmap();
    }
    //---------------------------------------------------------------------

    private void rbNonZero_Click(object sender, EventArgs e)
    {
      DrawBitmap(true);
    }
    //---------------------------------------------------------------------

    private void Form1_KeyDown(object sender, KeyEventArgs e)
    {
      switch (e.KeyCode)
      {
        case Keys.Escape:
          this.Close();
          return;
        case Keys.F1:
          MessageBox.Show(this.Text + "\nby Angus Johnson\nCopyright © 2010, 2011",
          this.Text, MessageBoxButtons.OK, MessageBoxIcon.Information);
          e.Handled = true;
          return;
        case Keys.Oemplus:
        case Keys.Add:
          if (nudOffset.Value == 10) return;
          nudOffset.Value += (decimal)0.5;
          e.Handled = true;
          break;
        case Keys.OemMinus:
        case Keys.Subtract:
          if (nudOffset.Value == -10) return;
          nudOffset.Value -= (decimal)0.5;
          e.Handled = true;
          break;
        case Keys.NumPad0:
        case Keys.D0:
          if (nudOffset.Value == 0) return;
          nudOffset.Value = (decimal)0;
          e.Handled = true;
          break;
        default: return;
      }

    }
    //---------------------------------------------------------------------

    private void nudCount_ValueChanged(object sender, EventArgs e)
    {
      DrawBitmap(true);
    }
    //---------------------------------------------------------------------

    private void rbTest1_Click(object sender, EventArgs e)
    {
      if (rbTest1.Checked)
        lblCount.Text = "Vertex &Count:";
      else
        lblCount.Text = "Ellipse &Count:";
      DrawBitmap();
    }
    //---------------------------------------------------------------------

    private void bSave_Click(object sender, EventArgs e)
    {
      //save to SVG ...
      if (saveFileDialog1.ShowDialog() == DialogResult.OK)
      {
        SVGBuilder svg = new SVGBuilder();
        svg.style.brushClr = Color.FromArgb(0x10, 0, 0, 0x9c);
        svg.style.penClr = Color.FromArgb(0xd3, 0xd3, 0xda);
        svg.AddPolygons(subjects);
        svg.style.brushClr = Color.FromArgb(0x10, 0x9c, 0, 0);
        svg.style.penClr = Color.FromArgb(0xff, 0xa0, 0x7a);
        svg.AddPolygons(clips);
        svg.style.brushClr = Color.FromArgb(0xAA, 0x80, 0xff, 0x9c);
        svg.style.penClr = Color.FromArgb(0, 0x33, 0);
        svg.AddPolygons(solution);
        svg.SaveToFile(saveFileDialog1.FileName, 1.0 / scale);
      }
    }
    //---------------------------------------------------------------------

  }
}
