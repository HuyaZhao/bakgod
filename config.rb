# encoding: utf-8

#ENV['BBS_ENV'] = 'development'
ROOT_PATH = File.dirname(__FILE__)

# upload image format
IMAGE_MIME_EXTENSIONS = %w[image/gif image/jpeg image/pjpeg image/x-png image/jpg image/png image/bmp]

# notification type
NOTIFICATION_TYPE = { 0 => '回复了', 1 => '@你在' }