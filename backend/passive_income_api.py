from flask import Flask, request, jsonify
from flask_cors import CORS
from datetime import datetime, timedelta
import redis
import json
import random
import hashlib
import os

app = Flask(__name__)
CORS(app)

# Redis configuration
REDIS_URL = os.environ.get('REDIS_URL', 'redis://localhost:6379')
redis_client = redis.from_url(REDIS_URL)

# Constants
MINING_RATE_PER_HOUR = 100.0
AUTO_CLICK_RATE = 10.0
DIVIDEND_RATE = 0.01
STAKING_APR = 0.365

def get_user_key(user_id):
    """Generate a unique key for each user"""
    return f"passive_income:{user_id}"

def get_user_data(user_id):
    """Get user data from Redis"""
    key = get_user_key(user_id)
    data = redis_client.get(key)
    if data:
        return json.loads(data)
    return {
        'balance': 0.0,
        'mining_power': 1.0,
        'auto_click_level': 0,
        'is_mining': False,
        'is_staking': False,
        'staked_amount': 0.0,
        'last_sync': datetime.now().isoformat(),
        'last_daily_bonus': None,
        'last_wheel_spin': None,
        'last_mystery_box': None,
        'total_earnings': 0.0,
        'mining_start_time': None,
        'staking_start_time': None,
    }

def save_user_data(user_id, data):
    """Save user data to Redis"""
    key = get_user_key(user_id)
    data['last_sync'] = datetime.now().isoformat()
    redis_client.set(key, json.dumps(data), ex=86400 * 30)  # Expire after 30 days

def calculate_mining_earnings(user_data):
    """Calculate mining earnings since last sync"""
    if not user_data['is_mining'] or not user_data['mining_start_time']:
        return 0

    start_time = datetime.fromisoformat(user_data['mining_start_time'])
    hours_passed = (datetime.now() - start_time).total_seconds() / 3600
    earnings = MINING_RATE_PER_HOUR * user_data['mining_power'] * hours_passed

    return earnings

def calculate_staking_rewards(user_data):
    """Calculate staking rewards since last sync"""
    if not user_data['is_staking'] or user_data['staked_amount'] <= 1000:
        return 0

    if not user_data['staking_start_time']:
        return 0

    start_time = datetime.fromisoformat(user_data['staking_start_time'])
    hours_passed = (datetime.now() - start_time).total_seconds() / 3600
    hourly_rate = STAKING_APR / 365 / 24
    rewards = user_data['staked_amount'] * hourly_rate * hours_passed

    return rewards

# API Endpoints

@app.route('/api/passive-income/sync', methods=['GET'])
def sync_data():
    """Sync user data with backend"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    # Calculate accumulated earnings
    mining_earnings = calculate_mining_earnings(user_data)
    staking_rewards = calculate_staking_rewards(user_data)

    # Update balance
    user_data['balance'] += mining_earnings + staking_rewards

    # Reset timers
    if user_data['is_mining']:
        user_data['mining_start_time'] = datetime.now().isoformat()
    if user_data['is_staking']:
        user_data['staking_start_time'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({
        'success': True,
        'balance': user_data['balance'],
        'miningPower': user_data['mining_power'],
        'autoClickLevel': user_data['auto_click_level'],
        'isMining': user_data['is_mining'],
        'isStaking': user_data['is_staking'],
        'totalEarnings': user_data['total_earnings'],
    })

@app.route('/api/passive-income/mining/start', methods=['POST'])
def start_mining():
    """Start mining"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    user_data['is_mining'] = True
    user_data['mining_start_time'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({'success': True})

@app.route('/api/passive-income/mining/stop', methods=['POST'])
def stop_mining():
    """Stop mining"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    # Calculate final earnings
    earnings = calculate_mining_earnings(user_data)
    user_data['balance'] += earnings
    user_data['total_earnings'] += earnings

    user_data['is_mining'] = False
    user_data['mining_start_time'] = None

    save_user_data(user_id, user_data)

    return jsonify({'success': True, 'earnings': earnings})

@app.route('/api/passive-income/mining/earnings', methods=['GET'])
def get_mining_earnings():
    """Get current mining earnings"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    earnings = calculate_mining_earnings(user_data)

    return jsonify({'earnings': earnings})

@app.route('/api/passive-income/mining/upgrade', methods=['POST'])
def upgrade_mining():
    """Upgrade mining power"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    upgrade_cost = user_data['mining_power'] * 1000

    if user_data['balance'] < upgrade_cost:
        return jsonify({'success': False, 'message': 'Insufficient balance'})

    user_data['balance'] -= upgrade_cost
    user_data['mining_power'] *= 1.5

    save_user_data(user_id, user_data)

    return jsonify({
        'success': True,
        'newPower': user_data['mining_power'],
        'balance': user_data['balance']
    })

@app.route('/api/passive-income/autoclick/upgrade', methods=['POST'])
def upgrade_autoclick():
    """Upgrade auto-click level"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    upgrade_cost = (user_data['auto_click_level'] + 1) * 500

    if user_data['balance'] < upgrade_cost:
        return jsonify({'success': False, 'message': 'Insufficient balance'})

    user_data['balance'] -= upgrade_cost
    user_data['auto_click_level'] += 1

    save_user_data(user_id, user_data)

    return jsonify({
        'success': True,
        'newLevel': user_data['auto_click_level'],
        'balance': user_data['balance']
    })

@app.route('/api/passive-income/staking/start', methods=['POST'])
def start_staking():
    """Start staking"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    amount = request.json.get('amount', user_data['balance'])

    if amount < 1000:
        return jsonify({'success': False, 'message': 'Minimum staking amount is 1000'})

    user_data['is_staking'] = True
    user_data['staked_amount'] = amount
    user_data['staking_start_time'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({'success': True})

@app.route('/api/passive-income/staking/rewards', methods=['GET'])
def get_staking_rewards():
    """Get staking rewards"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    rewards = calculate_staking_rewards(user_data)

    return jsonify({'rewards': rewards})

@app.route('/api/passive-income/bonus/daily', methods=['POST'])
def claim_daily_bonus():
    """Claim daily bonus"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    if user_data['last_daily_bonus']:
        last_claim = datetime.fromisoformat(user_data['last_daily_bonus'])
        if (datetime.now() - last_claim).total_seconds() < 86400:  # 24 hours
            return jsonify({'success': False, 'message': 'Already claimed today'})

    bonus = 100 + random.randint(0, 400)  # 100-500
    user_data['balance'] += bonus
    user_data['total_earnings'] += bonus
    user_data['last_daily_bonus'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({'success': True, 'amount': bonus})

@app.route('/api/passive-income/bonus/wheel', methods=['POST'])
def spin_wheel():
    """Spin lucky wheel"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    if user_data['last_wheel_spin']:
        last_spin = datetime.fromisoformat(user_data['last_wheel_spin'])
        if (datetime.now() - last_spin).total_seconds() < 10800:  # 3 hours
            return jsonify({'success': False, 'message': 'Wheel not ready'})

    prizes = [10, 20, 30, 50, 100, 200, 500, 1000]
    prize = random.choice(prizes)

    user_data['balance'] += prize
    user_data['total_earnings'] += prize
    user_data['last_wheel_spin'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({'success': True, 'prize': prize})

@app.route('/api/passive-income/bonus/mystery-box', methods=['POST'])
def open_mystery_box():
    """Open mystery box"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    if user_data['last_mystery_box']:
        last_open = datetime.fromisoformat(user_data['last_mystery_box'])
        if (datetime.now() - last_open).total_seconds() < 21600:  # 6 hours
            return jsonify({'success': False, 'message': 'Box not ready'})

    chance = random.random()

    if chance < 0.01:  # 1% - Diamond
        amount = 10000
        prize = '💎 Diamond Box'
    elif chance < 0.1:  # 9% - Gold
        amount = 1000
        prize = '🏆 Gold Box'
    elif chance < 0.3:  # 20% - Silver
        amount = 500
        prize = '🥈 Silver Box'
    else:  # 70% - Bronze
        amount = 100
        prize = '🥉 Bronze Box'

    user_data['balance'] += amount
    user_data['total_earnings'] += amount
    user_data['last_mystery_box'] = datetime.now().isoformat()

    save_user_data(user_id, user_data)

    return jsonify({
        'success': True,
        'prize': prize,
        'amount': amount
    })

@app.route('/api/passive-income/balance/update', methods=['POST'])
def update_balance():
    """Update user balance"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    amount = request.json.get('amount', 0)
    user_data['balance'] = amount

    save_user_data(user_id, user_data)

    return jsonify({'success': True})

@app.route('/api/passive-income/state/save', methods=['POST'])
def save_state():
    """Save complete state"""
    user_id = request.headers.get('X-User-Id', 'default')
    user_data = get_user_data(user_id)

    data = request.json
    user_data['balance'] = data.get('balance', user_data['balance'])
    user_data['mining_power'] = data.get('miningPower', user_data['mining_power'])
    user_data['auto_click_level'] = data.get('autoClickLevel', user_data['auto_click_level'])
    user_data['is_mining'] = data.get('isMining', user_data['is_mining'])

    save_user_data(user_id, user_data)

    return jsonify({'success': True})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port)