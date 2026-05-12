import request from '../utils/request'

export function uploadFile(file, parentId) {
  const formData = new FormData()
  formData.append('file', file)
  formData.append('parentId', parentId)
  
  return request({
    url: '/api/file/upload',
    method: 'post',
    data: formData,
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}

export function createFolder(folderName, parentId) {
  const formData = new FormData()
  formData.append('folderName', folderName)
  formData.append('parentId', parentId)
  
  return request({
    url: '/api/file/folder',
    method: 'post',
    data: formData
  })
}

export function getFileList(parentId) {
  return request({
    url: '/api/file/list',
    method: 'get',
    params: { parentId }
  })
}

export function downloadFile(id) {
  return request({
    url: `/api/file/download/${id}`,
    method: 'get',
    responseType: 'blob'
  })
}

export function deleteFile(id) {
  return request({
    url: `/api/file/${id}`,
    method: 'delete'
  })
}

export function getSpaceUsage() {
  return request({
    url: '/api/file/space',
    method: 'get'
  })
}
