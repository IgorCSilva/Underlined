<template>
  <div class="comment-thread">
    <CommentItem
      v-for="comment in list"
      :key="comment.id"
      :comment="comment"
      :base-path="basePath"
      @posted="onCommentAdded"
    />
    <div class="comment-thread-composer">
      <CommentComposer :base-path="basePath" @posted="onTopLevelPosted" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Comment } from '~/stores/comments'
import CommentItem from './CommentItem.vue'
import CommentComposer from './CommentComposer.vue'

const props = defineProps<{ basePath: string; comments: Comment[] }>()
const emit = defineEmits<{ 'comment-added': [] }>()

const list = ref<Comment[]>(props.comments)

function onTopLevelPosted(comment: Comment) {
  list.value.push(comment)
  onCommentAdded()
}

function onCommentAdded() {
  emit('comment-added')
}
</script>

<style scoped>
.comment-thread {
  margin-top: 8px;
}

.comment-thread-composer {
  padding-top: 16px;
}
</style>
