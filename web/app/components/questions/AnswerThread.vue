<template>
  <div class="answer-thread">
    <AnswerItem
      v-for="answer in list"
      :key="answer.id"
      :answer="answer"
      :can-mark-best="canMarkBest"
      @marked="onMarked"
    />
    <div class="answer-thread-composer">
      <AnswerComposer :question-id="questionId" @posted="onPosted" />
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Answer } from '~/stores/questions'
import AnswerItem from './AnswerItem.vue'
import AnswerComposer from './AnswerComposer.vue'

const props = defineProps<{ questionId: string; answers: Answer[]; canMarkBest: boolean }>()
const emit = defineEmits<{ 'answer-added': [] }>()

const list = ref<Answer[]>(props.answers)

function onPosted(answer: Answer) {
  list.value.push(answer)
  emit('answer-added')
}

function onMarked(updated: Answer) {
  list.value = list.value
    .map((answer) => ({ ...answer, best: answer.id === updated.id }))
    .sort((a, b) => Number(b.best) - Number(a.best))
}
</script>

<style scoped>
.answer-thread {
  margin-top: 16px;
  padding-left: 16px;
}

.answer-thread-composer {
  padding-top: 8px;
}
</style>
