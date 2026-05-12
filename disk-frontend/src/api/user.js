import request from '../utils/request'

export function login(data) {
  return request({
    url: '/api/user/login',
    method: 'post',
    data
  })
}

export function register(data) {
  return request({
    url: '/api/user/register',
    method: 'post',
    data
  })
}

export function sendVerifyCode(email) {
  return request({
    url: '/api/user/send-verify-code',
    method: 'post',
    data: { email }
  })
}

export function sendResetCode(email) {
  return request({
    url: '/api/user/send-reset-code',
    method: 'post',
    data: { email }
  })
}

export function resetPassword(data) {
  return request({
    url: '/api/user/reset-password',
    method: 'post',
    data
  })
}
