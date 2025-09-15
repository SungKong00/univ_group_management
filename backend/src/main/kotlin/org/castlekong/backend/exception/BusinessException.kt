package org.castlekong.backend.exception

class BusinessException(val errorCode: ErrorCode) : RuntimeException(errorCode.message)