"""Generate precise portfolio diagrams and a PDF print of the committed README."""
from pathlib import Path
from html import escape
import re
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib import font_manager
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Image, Table, TableStyle, PageBreak, Preformatted, KeepTogether
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.colors import HexColor, white
from reportlab.lib.pagesizes import A4
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont

ROOT = Path(__file__).resolve().parents[1]
IMAGES = ROOT/'docs/images'
BLUE = '#245b78'
DARK = '#183342'
GREEN = '#317360'
MUTED = '#526a78'
BG = '#f2f6f8'

def card(ax,x,y,w,h,title,body,colour=BLUE,fontsize=11):
    box=FancyBboxPatch((x-w/2,y-h/2),w,h,boxstyle='round,pad=0.13,rounding_size=0.12',
                       edgecolor=colour,facecolor=BG,linewidth=1.4,zorder=3)
    ax.add_patch(box)
    ax.text(x,y+h/2-min(.28,h*.13),title,ha='center',va='top',fontsize=12,fontweight='bold',color=colour,zorder=4)
    ax.text(x,y-.12,body,ha='center',va='center',fontsize=fontsize,linespacing=1.6,color=DARK,zorder=4)

def arrow(ax,a,b,colour=MUTED,rad=0):
    ax.add_patch(FancyArrowPatch(a,b,arrowstyle='-|>',mutation_scale=13,
                                 linewidth=1.25,color=colour,connectionstyle=f'arc3,rad={rad}',zorder=1))

def diagrams():
    IMAGES.mkdir(parents=True,exist_ok=True)
    plt.rcParams.update({'font.family':'DejaVu Sans','font.size':11})
    fig,ax=plt.subplots(figsize=(11.6,3.6));ax.set(xlim=(0,12),ylim=(0,3.9));ax.axis('off')
    ax.text(6,3.65,'The grain decides what can be compared',ha='center',fontsize=17,fontweight='bold',color=DARK)
    card(ax,3,2.6,4.6,1.15,'Expected fact: two product rows','SYN_INV_A → C_SHARED: 1 unit\nSYN_INV_B → C_SHARED: 2 units',fontsize=10.5)
    card(ax,9,2.6,4.6,1.15,'Actual fact: one component row','C_SHARED: 3 net units\nNo sold-product attribution',GREEN,fontsize=10.5)
    arrow(ax,(3,1.9),(4.75,1.45))
    arrow(ax,(9,1.9),(7.25,1.45))
    card(ax,6,.95,8.5,.8,'Compare at order / component / category / month','Expected 3 · Actual 3 · EUR 210 each · Variance EUR 0',fontsize=11)
    ax.text(6,.13,'A direct product-detail join would repeat the same actual 3 units twice.',ha='center',fontsize=10,color=MUTED)
    fig.tight_layout(pad=.6);fig.savefig(IMAGES/'grain.png',dpi=180,facecolor='white');plt.close(fig)

    fig,ax=plt.subplots(figsize=(11.6,6));ax.set(xlim=(0,12),ylim=(0,6.5));ax.axis('off')
    ax.text(6,6.25,'Conformed dimensions, two different fact grains',ha='center',fontsize=16,fontweight='bold',color=DARK)
    for x,title,body in [(2,'Order','ERP order identity'),(6,'Component','Physical item'),(10,'Valuation period','Order-derived month')]:
        card(ax,x,5.15,3.15,1.0,title,body,fontsize=10)
        arrow(ax,(x,4.5),(4.0,3.8),rad=.05)
        arrow(ax,(x,4.5),(8.8,3.8),rad=-.05)
    card(ax,4.0,3.0,3.6,1.3,'Expected cost fact','Order × sold SKU × component\n+ category + month',fontsize=10)
    card(ax,8.8,3.0,3.6,1.3,'Actual cost fact','Order × component\n+ category + month',GREEN,fontsize=10)
    card(ax,.9,3.0,1.35,1.3,'Sold\nproduct','SKU',fontsize=10)
    arrow(ax,(1.7,3.0),(2.0,3.0))
    arrow(ax,(4.0,2.2),(5.4,1.5))
    arrow(ax,(8.8,2.2),(7.4,1.5))
    card(ax,6.4,1.0,7.5,1.0,'Component reconciliation mart','Aggregate each fact, then compare at the shared grain',fontsize=10)
    ax.text(6,.13,'Portfolio serving layer added around the five exported calculations',ha='center',fontsize=9.5,color=MUTED)
    fig.tight_layout(pad=.6);fig.savefig(IMAGES/'star.png',dpi=180,facecolor='white');plt.close(fig)

def inline(text):
    parts=[];pos=0
    for m in re.finditer(r'\[([^\]]+)\]\(([^)]+)\)',text):
        parts.append(escape(text[pos:m.start()]))
        label,url=m.groups()
        if url.startswith(('https://','http://')):
            parts.append('<link href="'+escape(url,quote=True)+'" color="#245b78">'+escape(label)+'</link>')
        else:
            parts.append(escape(label))
        pos=m.end()
    parts.append(escape(text[pos:]))
    text=''.join(parts)
    text = re.sub(r'\*\*([^*]+)\*\*',r'<b>\1</b>',text)
    return re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)',r'<i>\1</i>',text)

def build_pdf():
    regular=font_manager.findfont('DejaVu Sans')
    bold=font_manager.findfont(font_manager.FontProperties(family='DejaVu Sans',weight='bold'))
    mono=font_manager.findfont('DejaVu Sans Mono')
    italic=font_manager.findfont(font_manager.FontProperties(family='DejaVu Sans',style='oblique'))
    pdfmetrics.registerFont(TTFont('Body',regular));pdfmetrics.registerFont(TTFont('BodyBold',bold))
    pdfmetrics.registerFont(TTFont('Code',mono));pdfmetrics.registerFont(TTFont('BodyItalic',italic))
    pdfmetrics.registerFontFamily('Body',normal='Body',bold='BodyBold',italic='BodyItalic')
    styles={
      'h1':ParagraphStyle('H1',fontName='BodyBold',fontSize=22,leading=27,textColor=HexColor(DARK),spaceAfter=13),
      'h2':ParagraphStyle('H2',fontName='BodyBold',fontSize=12.5,leading=17,textColor=HexColor(BLUE),spaceBefore=10,spaceAfter=8,keepWithNext=True),
      'body':ParagraphStyle('Body',fontName='Body',fontSize=9,leading=12.4,textColor=HexColor(DARK),spaceAfter=7),
      'cell':ParagraphStyle('Cell',fontName='Body',fontSize=7.5,leading=10.1,textColor=HexColor(DARK)),
      'th':ParagraphStyle('TH',fontName='BodyBold',fontSize=7.4,leading=10,textColor=white),
      'code':ParagraphStyle('Code',fontName='Code',fontSize=8,leading=11,textColor=HexColor(DARK),backColor=HexColor(BG),borderPadding=7,spaceBefore=4,spaceAfter=10),
      'caption':ParagraphStyle('Caption',fontName='Body',fontSize=7.5,leading=10.5,textColor=HexColor(MUTED),spaceAfter=10),
      'bullet':ParagraphStyle('Bullet',fontName='Body',fontSize=9.1,leading=13.2,textColor=HexColor(DARK),leftIndent=10,firstLineIndent=-8,spaceAfter=7),
    }
    width=A4[0]-36*mm
    story=[]
    lines=(ROOT/'README.md').read_text().splitlines();i=0
    while i<len(lines):
        line=lines[i].strip()
        if not line:i+=1;continue
        if line=='<!-- pagebreak -->':
            story.append(PageBreak());i+=1;continue
        if line.startswith('~~~'):
            code=[];i+=1
            while i<len(lines) and not lines[i].startswith('~~~'):code.append(lines[i]);i+=1
            story.append(Preformatted('\n'.join(code),styles['code']));i+=1;continue
        image=re.fullmatch(r'!\[([^\]]*)\]\(([^)]+)\)',line)
        if image:
            alt,path=image.groups();image_path=ROOT/path
            from PIL import Image as PILImage
            with PILImage.open(image_path) as im:w,h=im.size
            story.append(Image(str(image_path),width=width,height=width*h/w))
            story.append(Paragraph(inline(alt),styles['caption']));i+=1;continue
        if line.startswith('|'):
            rows=[]
            while i<len(lines) and lines[i].strip().startswith('|'):
                cells=[x.strip() for x in lines[i].strip().strip('|').split('|')]
                if not all(re.fullmatch(r'[:\- ]+',x) for x in cells):rows.append(cells)
                i+=1
            n=len(rows[0])
            proportions={2:[.34,.66],3:[.18,.43,.39],6:[.2,.11,.21,.13,.21,.14]}.get(n,[1/n]*n)
            table=Table([[Paragraph(inline(c),styles['th'] if j==0 else styles['cell']) for c in row] for j,row in enumerate(rows)],
                        colWidths=[width*x for x in proportions],repeatRows=1,hAlign='LEFT')
            table.setStyle(TableStyle([
                ('BACKGROUND',(0,0),(-1,0),HexColor(BLUE)),
                ('ROWBACKGROUNDS',(0,1),(-1,-1),[HexColor('#f1f5f7'),white]),
                ('VALIGN',(0,0),(-1,-1),'TOP'),('LEFTPADDING',(0,0),(-1,-1),6),
                ('RIGHTPADDING',(0,0),(-1,-1),6),('TOPPADDING',(0,0),(-1,-1),5),
                ('BOTTOMPADDING',(0,0),(-1,-1),5),
                ('LINEBELOW',(0,0),(-1,0),.5,white),
                ('LINEBELOW',(0,1),(-1,-1),.3,HexColor('#d5e0e6')),
            ]))
            story.extend([table,Spacer(1,10)]);continue
        if line.startswith('# '):
            story.append(Paragraph(inline(line[2:]),styles['h1']));i+=1;continue
        if line.startswith('## '):
            story.append(Paragraph(inline(line[3:]),styles['h2']));i+=1;continue
        if line.startswith('- '):
            story.append(Paragraph('• '+inline(line[2:]),styles['bullet']));i+=1;continue
        paragraph=[line];i+=1
        while i<len(lines) and lines[i].strip() and not lines[i].startswith(('#','|','~~~','![','<!--','- ')):
            paragraph.append(lines[i].strip());i+=1
        story.append(Paragraph(inline(' '.join(paragraph)),styles['body']))
    def footer(canvas,doc):
        canvas.saveState();canvas.setStrokeColor(HexColor('#d5e0e6'))
        canvas.line(18*mm,15*mm,A4[0]-18*mm,15*mm)
        canvas.setFillColor(HexColor(MUTED));canvas.setFont('Body',7)
        canvas.drawString(18*mm,10.5*mm,'Filippo Carraro | Component cost reconciliation | Synthetic portfolio demo')
        canvas.drawRightString(A4[0]-18*mm,10.5*mm,str(doc.page));canvas.restoreState()
    path=ROOT/'docs/README.pdf'
    doc=SimpleDocTemplate(str(path),pagesize=A4,leftMargin=18*mm,rightMargin=18*mm,topMargin=17*mm,bottomMargin=22*mm,
                          title='From sales promise to component cost',author='Filippo Carraro')
    doc.build(story,onFirstPage=footer,onLaterPages=footer)
    print(path)

if __name__=='__main__':
    diagrams()
    build_pdf()
