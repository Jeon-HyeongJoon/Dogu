from fastapi import APIRouter, Depends
from fastapi.responses import HTMLResponse

from app.models import SeedData
from app.repository import repository
from app.security import require_admin


router = APIRouter(tags=["admin"], dependencies=[Depends(require_admin)])


@router.get("/admin", response_class=HTMLResponse)
def admin_page() -> str:
    data = repository.data
    return f"""
<!doctype html>
<html lang=\"ko\">
  <head>
    <meta charset=\"utf-8\" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <title>Dogu Admin</title>
    <style>
      body {{ font-family: sans-serif; margin: 0; padding: 24px; background: #fff; color: #111; }}
      h1 {{ margin-top: 0; }}
      .grid {{ display: grid; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); gap: 12px; margin-bottom: 24px; }}
      .card {{ border: 1px solid #e6e6e5; padding: 16px; }}
      textarea {{ width: 100%; min-height: 360px; font-family: monospace; font-size: 12px; }}
      button {{ height: 44px; padding: 0 18px; border: 1px solid #13402d; background: #13402d; color: white; cursor: pointer; }}
      pre {{ white-space: pre-wrap; background: #fafafa; border: 1px solid #e6e6e5; padding: 12px; }}
    </style>
  </head>
  <body>
    <h1>Dogu Admin</h1>
    <div class=\"grid\">
      <div class=\"card\"><strong>카테고리</strong><div>{len(data.categories)}</div></div>
      <div class=\"card\"><strong>상품</strong><div>{len(data.products)}</div></div>
      <div class=\"card\"><strong>트렌딩</strong><div>{len(data.trending)}</div></div>
      <div class=\"card\"><strong>주문</strong><div id=\"order-count\">{len(repository.orders)}</div></div>
    </div>
    <h2>홈 드랍 광고 관리</h2>
    <div class=\"grid\">
      <div class=\"card\"><strong>Hero Eyebrow</strong><div id=\"hero-eyebrow\">{data.home.hero.eyebrow}</div></div>
      <div class=\"card\"><strong>Hero Title</strong><div id=\"hero-title\">{data.home.hero.title}</div></div>
      <div class=\"card\"><strong>Featured Product ID</strong><div id=\"hero-featured\">{data.home.featured_product_id}</div></div>
      <div class=\"card\"><strong>Collections</strong><div id=\"hero-collections\">{len(data.home.collections)}</div></div>
    </div>
    <p>아래 Seed JSON에서 <code>home.hero</code>, <code>home.featured_product_id</code>, <code>home.collections</code>를 수정하면 홈 상단 드랍 광고 영역에 반영됩니다.</p>
    <h2>Seed JSON 관리</h2>
    <p>관리자 인증(HTTP Basic) 후 현재 시드 데이터를 보고 저장할 수 있습니다.</p>
    <textarea id=\"seed-editor\"></textarea>
    <p><button id=\"save-seed\">시드 저장</button></p>
    <h2>최근 주문</h2>
    <pre id=\"orders\">[]</pre>
    <script>
      async function loadSeed() {{
        const response = await fetch('/api/manage/seed');
        const data = await response.json();
        document.getElementById('seed-editor').value = JSON.stringify(data, null, 2);
      }}
      async function loadOrders() {{
        const response = await fetch('/api/orders');
        const data = await response.json();
        document.getElementById('orders').textContent = JSON.stringify(data, null, 2);
        document.getElementById('order-count').textContent = data.length;
      }}
      document.getElementById('save-seed').addEventListener('click', async () => {{
        const payload = JSON.parse(document.getElementById('seed-editor').value);
        const response = await fetch('/api/manage/seed', {{
          method: 'POST',
          headers: {{ 'content-type': 'application/json' }},
          body: JSON.stringify(payload)
        }});
        if (!response.ok) {{
          alert('시드 저장 실패');
          return;
        }}
        alert('시드 저장 완료');
        await loadSeed();
      }});
      loadSeed();
      loadOrders();
    </script>
  </body>
</html>
"""


@router.get("/api/manage/seed", response_model=SeedData)
def get_seed() -> SeedData:
    return repository.data


@router.post("/api/manage/seed", response_model=SeedData)
def save_seed(payload: SeedData) -> SeedData:
    repository.save_seed(payload)
    return repository.data
