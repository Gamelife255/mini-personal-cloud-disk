import request from '../utils/request'

export function getStatisticsOverview() {
  return request({
    url: '/api/statistics/overview',
    method: 'get'
  })
}

export function getFileTypeDistribution() {
  return request({
    url: '/api/statistics/file-types',
    method: 'get'
  })
}

export function getUploadHistory() {
  return request({
    url: '/api/statistics/upload-history',
    method: 'get'
  })
}
