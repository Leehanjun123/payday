from flask import Flask, request, jsonify
from flask_cors import CORS
import os
import requests
from datetime import datetime, timedelta
import hashlib
import hmac
import json

app = Flask(__name__)
CORS(app)

# API Keys (환경변수로 관리)
COUPANG_ACCESS_KEY = os.environ.get('COUPANG_ACCESS_KEY')
COUPANG_SECRET_KEY = os.environ.get('COUPANG_SECRET_KEY')
YOUTUBE_API_KEY = os.environ.get('YOUTUBE_API_KEY')
NAVER_CLIENT_ID = os.environ.get('NAVER_CLIENT_ID')
NAVER_CLIENT_SECRET = os.environ.get('NAVER_CLIENT_SECRET')

# 쿠팡 파트너스 API
class CoupangPartners:
    def __init__(self):
        self.access_key = COUPANG_ACCESS_KEY
        self.secret_key = COUPANG_SECRET_KEY
        self.base_url = "https://api-gateway.coupang.com"

    def generate_hmac(self, path, method="GET", query=""):
        message = datetime.utcnow().strftime('%y%m%d') + 'T' + datetime.utcnow().strftime('%H%M%S') + 'Z'
        message += method
        message += path
        if query:
            message += query

        signature = hmac.new(
            self.secret_key.encode('utf-8'),
            message.encode('utf-8'),
            hashlib.sha256
        ).hexdigest()

        return f"CEA algorithm={self.access_key}, signature={signature}"

    def get_products(self, keyword, limit=20):
        """상품 검색 API"""
        path = "/v2/providers/affiliate_open_api/apis/openapi/products/search"
        params = {
            "keyword": keyword,
            "limit": limit
        }

        headers = {
            "Authorization": self.generate_hmac(path),
            "Content-Type": "application/json"
        }

        response = requests.get(
            f"{self.base_url}{path}",
            headers=headers,
            params=params
        )

        return response.json() if response.status_code == 200 else None

    def get_earnings(self, start_date, end_date):
        """수익 조회 API"""
        path = "/v2/providers/affiliate_open_api/apis/openapi/reports/earnings"
        params = {
            "startDate": start_date,
            "endDate": end_date
        }

        headers = {
            "Authorization": self.generate_hmac(path),
            "Content-Type": "application/json"
        }

        response = requests.get(
            f"{self.base_url}{path}",
            headers=headers,
            params=params
        )

        return response.json() if response.status_code == 200 else None

# 유튜브 Analytics API
class YouTubeAnalytics:
    def __init__(self):
        self.api_key = YOUTUBE_API_KEY
        self.base_url = "https://youtubeanalytics.googleapis.com/v2"

    def get_channel_stats(self, channel_id):
        """채널 통계 조회"""
        url = f"https://www.googleapis.com/youtube/v3/channels"
        params = {
            "part": "statistics,snippet",
            "id": channel_id,
            "key": self.api_key
        }

        response = requests.get(url, params=params)
        return response.json() if response.status_code == 200 else None

    def get_estimated_revenue(self, channel_id):
        """예상 수익 계산 (조회수 기반)"""
        stats = self.get_channel_stats(channel_id)
        if stats and stats.get('items'):
            views = int(stats['items'][0]['statistics'].get('viewCount', 0))
            # CPM $1-5 기준 예상 수익 계산
            estimated_revenue = (views / 1000) * 2.5  # 평균 CPM $2.5
            return {
                "views": views,
                "estimated_revenue_usd": estimated_revenue,
                "estimated_revenue_krw": estimated_revenue * 1300
            }
        return None

# 네이버 애드포스트 API
class NaverAdPost:
    def __init__(self):
        self.client_id = NAVER_CLIENT_ID
        self.client_secret = NAVER_CLIENT_SECRET
        self.base_url = "https://openapi.naver.com"

    def get_blog_stats(self, blog_url):
        """블로그 통계 조회"""
        headers = {
            "X-Naver-Client-Id": self.client_id,
            "X-Naver-Client-Secret": self.client_secret
        }

        # 네이버 블로그 검색 API로 대체
        url = f"{self.base_url}/v1/search/blog"
        params = {
            "query": blog_url,
            "display": 10
        }

        response = requests.get(url, headers=headers, params=params)
        return response.json() if response.status_code == 200 else None

# API 엔드포인트들

@app.route('/api/platforms/coupang_partners/earnings', methods=['GET'])
def get_coupang_earnings():
    """쿠팡 파트너스 수익 조회"""
    if not COUPANG_ACCESS_KEY:
        return jsonify({
            "error": "Coupang Partners API key not configured",
            "mock_data": {
                "daily_earnings": 12500,
                "monthly_earnings": 385000,
                "total_clicks": 1523,
                "conversion_rate": 3.2
            }
        })

    cp = CoupangPartners()
    today = datetime.now().strftime('%Y%m%d')
    month_ago = (datetime.now() - timedelta(days=30)).strftime('%Y%m%d')

    earnings = cp.get_earnings(month_ago, today)

    if earnings:
        return jsonify(earnings)
    else:
        return jsonify({
            "daily_earnings": 0,
            "monthly_earnings": 0,
            "error": "Failed to fetch data"
        })

@app.route('/api/platforms/coupang_partners/products', methods=['GET'])
def search_coupang_products():
    """쿠팡 상품 검색"""
    keyword = request.args.get('keyword', '추천상품')

    if not COUPANG_ACCESS_KEY:
        return jsonify({
            "products": [
                {
                    "name": "샘플 상품 1",
                    "price": 15000,
                    "commission_rate": 3,
                    "link": "https://link.coupang.com/sample1"
                },
                {
                    "name": "샘플 상품 2",
                    "price": 25000,
                    "commission_rate": 5,
                    "link": "https://link.coupang.com/sample2"
                }
            ]
        })

    cp = CoupangPartners()
    products = cp.get_products(keyword)

    return jsonify(products) if products else jsonify({"products": []})

@app.route('/api/platforms/youtube/earnings', methods=['GET'])
def get_youtube_earnings():
    """유튜브 수익 조회"""
    channel_id = request.args.get('channel_id')

    if not YOUTUBE_API_KEY:
        return jsonify({
            "error": "YouTube API key not configured",
            "mock_data": {
                "daily_views": 5234,
                "daily_earnings_krw": 6800,
                "monthly_earnings_krw": 204000,
                "subscribers": 1523
            }
        })

    yt = YouTubeAnalytics()
    revenue = yt.get_estimated_revenue(channel_id)

    return jsonify(revenue) if revenue else jsonify({"error": "Failed to fetch data"})

@app.route('/api/platforms/naver_adpost/earnings', methods=['GET'])
def get_naver_earnings():
    """네이버 애드포스트 수익 조회"""
    blog_url = request.args.get('blog_url')

    if not NAVER_CLIENT_ID:
        return jsonify({
            "error": "Naver API key not configured",
            "mock_data": {
                "daily_clicks": 234,
                "daily_earnings_krw": 2340,
                "monthly_earnings_krw": 70200,
                "cpc_average": 10
            }
        })

    naver = NaverAdPost()
    stats = naver.get_blog_stats(blog_url)

    if stats:
        # 실제로는 애드포스트 API가 필요하지만, 검색 API로 대체
        return jsonify({
            "blog_posts": stats.get('total', 0),
            "estimated_daily_earnings": 1000,  # 예상치
            "message": "Actual AdPost API required for real data"
        })

    return jsonify({"error": "Failed to fetch data"})

@app.route('/api/platforms/<platform_id>/connect', methods=['POST'])
def connect_platform(platform_id):
    """플랫폼 연결"""
    user_id = request.headers.get('X-User-Id', 'default')
    data = request.json

    # 플랫폼별 인증 처리
    connection_info = {
        "platform_id": platform_id,
        "user_id": user_id,
        "connected_at": datetime.now().isoformat(),
        "status": "connected"
    }

    # Redis나 DB에 저장
    # redis_client.set(f"connection:{user_id}:{platform_id}", json.dumps(connection_info))

    return jsonify({
        "success": True,
        "platform_id": platform_id,
        "message": f"{platform_id} connected successfully"
    })

@app.route('/api/platforms/<platform_id>/disconnect', methods=['POST'])
def disconnect_platform(platform_id):
    """플랫폼 연결 해제"""
    user_id = request.headers.get('X-User-Id', 'default')

    # Redis나 DB에서 삭제
    # redis_client.delete(f"connection:{user_id}:{platform_id}")

    return jsonify({
        "success": True,
        "platform_id": platform_id,
        "message": f"{platform_id} disconnected"
    })

@app.route('/api/platforms/walking/sync', methods=['POST'])
def sync_walking_apps():
    """걷기 앱 데이터 동기화"""
    user_id = request.headers.get('X-User-Id', 'default')
    data = request.json

    steps = data.get('steps', 0)
    apps = data.get('apps', [])

    # 각 앱별 예상 수익 계산
    earnings = {}

    if 'cashwalk' in apps:
        earnings['cashwalk'] = min(steps / 100, 200)  # 100보당 1캐시, 최대 200

    if 'toss' in apps:
        earnings['toss'] = 911 if steps >= 10000 else steps * 0.0911

    if 'cashdoc' in apps:
        earnings['cashdoc'] = min(steps / 100, 150)

    total_earnings = sum(earnings.values())

    return jsonify({
        "success": True,
        "steps": steps,
        "earnings_by_app": earnings,
        "total_earnings": total_earnings
    })

@app.route('/api/platforms/survey/available', methods=['GET'])
def get_available_surveys():
    """가능한 설문조사 목록"""
    surveys = [
        {
            "id": "panel_now_1",
            "platform": "패널나우",
            "title": "2024 소비 트렌드 조사",
            "reward": 2000,
            "duration": 10,
            "available": True
        },
        {
            "id": "embrain_1",
            "platform": "엠브레인",
            "title": "모바일 앱 사용 패턴 조사",
            "reward": 3500,
            "duration": 15,
            "available": True
        },
        {
            "id": "panel_now_2",
            "platform": "패널나우",
            "title": "온라인 쇼핑 만족도 조사",
            "reward": 1500,
            "duration": 7,
            "available": True
        }
    ]

    return jsonify({
        "surveys": surveys,
        "total_available": len(surveys),
        "total_rewards": sum(s['reward'] for s in surveys)
    })

@app.route('/api/platforms/delivery/opportunities', methods=['GET'])
def get_delivery_opportunities():
    """배달/배송 기회 조회"""
    location = request.args.get('location', '서울')

    opportunities = {
        "baemin_connect": {
            "available_zones": 15,
            "average_earning_per_delivery": 4500,
            "peak_hours": ["11:00-14:00", "18:00-21:00"],
            "bonus_available": True
        },
        "coupang_flex": {
            "available_blocks": 8,
            "earning_per_block": 22000,
            "block_duration": "3-4시간",
            "new_driver_bonus": 50000
        }
    }

    return jsonify(opportunities)

@app.route('/api/platforms/stats/summary', methods=['GET'])
def get_platform_summary():
    """전체 플랫폼 통계 요약"""
    user_id = request.headers.get('X-User-Id', 'default')

    # 실제로는 DB에서 조회
    summary = {
        "total_platforms_connected": 5,
        "today_earnings": 15234,
        "this_month_earnings": 458700,
        "total_earnings": 2345600,
        "most_profitable_platform": "쿠팡 파트너스",
        "daily_average": 15290,
        "platforms": [
            {"name": "쿠팡 파트너스", "earnings": 385000},
            {"name": "캐시워크", "earnings": 6000},
            {"name": "토스", "earnings": 27330},
            {"name": "유튜브", "earnings": 204000},
            {"name": "패널나우", "earnings": 35000}
        ]
    }

    return jsonify(summary)

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(host='0.0.0.0', port=port)