import request from '../utils/request'

export function getUsers() {
  return request({
    url: '/api/admin/users',
    method: 'get'
  })
}

export function updateUserStatus(id, status) {
  return request({
    url: `/api/admin/user/${id}/status`,
    method: 'put',
    data: { status }
  })
}

export function resetUserPassword(id, password) {
  return request({
    url: `/api/admin/user/${id}/reset-password`,
    method: 'put',
    data: { password }
  })
}

export function getUserFiles(id, parentId = 0) {
  return request({
    url: `/api/admin/user/${id}/files`,
    method: 'get',
    params: { parentId }
  })
}
